// lib/features/private_note/application/private_note_edit_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/core/crypto/crypto_provider.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';
import 'package:uuid/uuid.dart';

class PrivateNoteEditState {
  final bool opening;
  final bool saving;
  final String? error;
  final NoteBase? note;

  /// 是否已落盘（Hive里存在）
  final bool persisted;

  const PrivateNoteEditState({
    this.opening = true,
    this.saving = false,
    this.error,
    this.note,
    this.persisted = false,
  });

  PrivateNoteEditState copyWith({
    bool? opening,
    bool? saving,
    String? error,
    NoteBase? note,
    bool? persisted,
    bool clearError = false,
  }) {
    return PrivateNoteEditState(
      opening: opening ?? this.opening,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      note: note ?? this.note,
      persisted: persisted ?? this.persisted,
    );
  }
}

/// ✅ 别忘了这个 provider
final privateNoteEditControllerProvider =
    AsyncNotifierProvider<PrivateNoteEditController, PrivateNoteEditState>(
      PrivateNoteEditController.new,
    );

class PrivateNoteEditController extends AsyncNotifier<PrivateNoteEditState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);
  final _uuid = const Uuid();

  @override
  Future<PrivateNoteEditState> build() async {
    return const PrivateNoteEditState(opening: true);
  }

  Future<void> open({String? noteId}) async {
    final prev = state.value ?? const PrivateNoteEditState();
    state = AsyncData(prev.copyWith(opening: true, clearError: true));

    try {
      NoteBase? note;
      var persisted = false;

      if (noteId != null && noteId.trim().isNotEmpty) {
        note = await _repo.getById(noteId.trim());
        if (note != null && note.kind != NoteKind.privateNote) {
          note = null;
        }
        persisted = note != null;
        // ✅ 解密回填：如果有 enc 并且本机有 masterKey，就把 content 解出来给编辑器
        if (note != null) {
          final enc = note.enc;
          if (enc != null && enc.isNotEmpty) {
            final crypto = ref.read(cryptoProvider);
            if (crypto.hasMasterKey) {
              try {
                final plain = ref
                    .read(cryptoProvider.notifier)
                    .decryptEncToText(enc);
                note = note.copyWith(content: plain);
              } catch (_) {
                // note 保持原样，但给用户一个提示
                final prev = state.value ?? const PrivateNoteEditState();
                state = AsyncData(
                  prev.copyWith(
                    error: 'Decrypt failed. Please restore your master key.',
                  ),
                );
              }
            }
          }
        }
      }

      note ??= _newDraft(noteId: noteId);

      state = AsyncData(
        (state.value ?? const PrivateNoteEditState()).copyWith(
          opening: false,
          note: note,
          persisted: persisted,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? const PrivateNoteEditState()).copyWith(
          opening: false,
          error: e.toString(),
        ),
      );
    }
  }

  void setContent(String text) {
    final s = state.value;
    final cur = s?.note;
    if (cur == null) return;

    state = AsyncData(
      s!.copyWith(
        note: cur.copyWith(
          content: text,
          enc: null,
          updatedAt: DateTime.now(),
          isSynced: false,
        ),
      ),
    );
  }

  Future<void> save() async {
    final s = state.value;
    final cur = s?.note;
    if (s == null || cur == null) return;
    if (s.saving) return;

    state = AsyncData(s.copyWith(saving: true, clearError: true));

    try {
      final content = (cur.content ?? '').trim();

      // 1) 新建空白笔记：不创建
      if (content.isEmpty && !s.persisted) {
        state = AsyncData(
          (state.value ?? const PrivateNoteEditState()).copyWith(
            saving: false,
            clearError: true,
          ),
        );
        return;
      }

      final now = DateTime.now();
      final nextVersion = s.persisted ? (cur.version + 1) : 1;

      final crypto = ref.read(cryptoProvider);

      NoteBase toSave;

      // 2) 有 masterKey：加密保存
      if (crypto.hasMasterKey) {
        final enc = ref.read(cryptoProvider.notifier).encryptTextToEnc(content);

        toSave = cur.copyWith(
          content: content, // 你当前编辑页/list 仍依赖 content，这里先保留
          enc: enc,
          updatedAt: now,
          isSynced: false,
          isDeleted: false,
          version: nextVersion,
        );
      } else {
        // 3) 没有 masterKey：明文保存，不抛错
        toSave = cur.copyWith(
          content: content,
          enc: null,
          updatedAt: now,
          isSynced: false,
          isDeleted: false,
          version: nextVersion,
        );
      }

      await _repo.upsert(toSave);

      state = AsyncData(
        (state.value ?? const PrivateNoteEditState()).copyWith(
          persisted: true,
          note: toSave,
          saving: false,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? const PrivateNoteEditState()).copyWith(
          saving: false,
          error: e.toString(),
        ),
      );
    }
  }

  NoteBase _newDraft({String? noteId}) {
    final id = (noteId != null && noteId.trim().isNotEmpty)
        ? noteId.trim()
        : 'pn_${_uuid.v4()}';

    final now = DateTime.now();
    const userId = '';

    return NoteBase(
      id: id,
      userId: userId,
      kind: NoteKind.privateNote,
      createdAt: now,
      updatedAt: now,
      content: '',
      enc: null,
      serverNoteId: null,
      isSynced: false,
      isDeleted: false,
      version: 1,
      meta: const {},
    );
  }
}
