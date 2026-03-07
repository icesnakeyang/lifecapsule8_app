import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final lastWishesEditControllerProvider =
    AsyncNotifierProvider<LastWishesEditController, LastWishesEditState>(
      LastWishesEditController.new,
    );

class LastWishesEditState {
  final bool loading;
  final bool saving;

  /// 是否已存在于 notes_box（即之前 upsert 过）
  final bool persisted;

  final String? error;

  final NoteBase? note;

  const LastWishesEditState({
    this.loading = true,
    this.saving = false,
    this.persisted = false,
    this.error,
    this.note,
  });

  LastWishesEditState copyWith({
    bool? loading,
    bool? saving,
    bool? persisted,
    String? error,
    bool clearError = false,
    NoteBase? note,
  }) {
    return LastWishesEditState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      persisted: persisted ?? this.persisted,
      error: clearError ? null : (error ?? this.error),
      note: note ?? this.note,
    );
  }
}

class LastWishesEditController extends AsyncNotifier<LastWishesEditState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  static const String _noteId = 'last_wishes';

  Timer? _debounce;

  @override
  Future<LastWishesEditState> build() async {
    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
    });

    final base = const LastWishesEditState(loading: true);

    try {
      final existing = await _repo.getById(_noteId);

      if (existing != null && existing.isDeleted != true) {
        // ✅ 已有草稿
        return base.copyWith(
          loading: false,
          persisted: true,
          note: existing,
          clearError: true,
        );
      }

      // ✅ 没有就创建一个内存草稿（不立即写入，避免空数据污染）
      final now = DateTime.now();
      final draft = NoteBase(
        id: _noteId,
        userId: 'userId',
        kind: NoteKind.lastWishes, // ⚠️ 你需要在 NoteKind 里加 lastWishes
        content: '',
        meta: const {},
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      return base.copyWith(
        loading: false,
        persisted: false,
        note: draft,
        clearError: true,
      );
    } catch (e) {
      return base.copyWith(loading: false, error: e.toString());
    }
  }

  // ---------------- UI actions ----------------

  void setContent(String text) {
    final s = state.value;
    if (s == null) return;
    final n = s.note;
    if (n == null) return;

    final now = DateTime.now();
    final updated = n.copyWith(content: text, updatedAt: now, isDeleted: false);

    state = AsyncData(s.copyWith(note: updated, clearError: true));

    _scheduleSave();
  }

  Future<void> saveNow() async {
    final s = state.value;
    if (s == null) return;
    final n = s.note;
    if (n == null) return;
    if (s.saving) return;

    // ✅ content 可能为 null，必须兜底
    final content = (n.content ?? '').trim();

    state = AsyncData(s.copyWith(saving: true, clearError: true));

    try {
      if (content.isEmpty) {
        // 空内容：如果之前写入过，就标记删除；否则什么都不做
        if (s.persisted) {
          await _repo.markDeleted(n.id);
          state = AsyncData(s.copyWith(saving: false, persisted: false));
        } else {
          state = AsyncData(s.copyWith(saving: false));
        }
        return;
      }

      // 非空：upsert
      await _repo.upsert(n.copyWith(content: content, isDeleted: false));

      // upsert 成功后认为 persisted
      state = AsyncData(
        (state.value ?? s).copyWith(
          saving: false,
          persisted: true,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? s).copyWith(saving: false, error: e.toString()),
      );
    }
  }

  // ---------------- internal ----------------

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      await saveNow();
    });
  }
}
