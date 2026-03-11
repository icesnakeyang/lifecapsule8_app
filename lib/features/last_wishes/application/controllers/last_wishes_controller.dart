// lib/features/last_wishes/application/last_wishes_controller.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final lastWishesControllerProvider =
    StateNotifierProvider.family<
      LastWishesController,
      AsyncValue<LastWishesState>,
      String
    >((ref, noteId) {
      final repo = ref.read(notesRepositoryProvider);
      return LastWishesController(repo: repo, noteId: noteId);
    });

class LastWishesState {
  final bool loading;
  final bool saving;
  final bool submitting;
  final bool persisted;
  final String? error;

  final String noteId;
  final NoteBase? note;

  final String content;
  final String email;
  final String confirmEmail;
  final int? waitingYears;
  final String messageNote;
  final bool enabled;

  const LastWishesState({
    this.loading = false,
    this.saving = false,
    this.submitting = false,
    this.persisted = false,
    this.error,
    required this.noteId,
    this.note,
    this.content = '',
    this.email = '',
    this.confirmEmail = '',
    this.waitingYears,
    this.messageNote = '',
    this.enabled = false,
  });

  factory LastWishesState.initial(String noteId) {
    return LastWishesState(loading: true, noteId: noteId);
  }

  LastWishesState copyWith({
    bool? loading,
    bool? saving,
    bool? submitting,
    bool? persisted,
    String? error,
    bool clearError = false,
    String? noteId,
    NoteBase? note,
    String? content,
    String? email,
    String? confirmEmail,
    int? waitingYears,
    bool clearWaitingYears = false,
    String? messageNote,
    bool? enabled,
  }) {
    return LastWishesState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      submitting: submitting ?? this.submitting,
      persisted: persisted ?? this.persisted,
      error: clearError ? null : (error ?? this.error),
      noteId: noteId ?? this.noteId,
      note: note ?? this.note,
      content: content ?? this.content,
      email: email ?? this.email,
      confirmEmail: confirmEmail ?? this.confirmEmail,
      waitingYears: clearWaitingYears
          ? null
          : (waitingYears ?? this.waitingYears),
      messageNote: messageNote ?? this.messageNote,
      enabled: enabled ?? this.enabled,
    );
  }

  bool get canGoEditNext => content.trim().isNotEmpty;

  bool get canGoRecipientNext {
    if (!_isValidEmail(email)) return false;
    if (email.trim() != confirmEmail.trim()) return false;
    if (waitingYears == null) return false;
    if (waitingYears! < 1) return false;
    return true;
  }

  bool get canConfirm {
    if (submitting) return false;
    if (enabled) return false;
    if (content.trim().isEmpty) return false;
    if (!_isValidEmail(email)) return false;
    if (waitingYears == null || waitingYears! < 1) return false;
    return true;
  }

  static bool _isValidEmail(String value) {
    final v = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
  }
}

class LastWishesController extends StateNotifier<AsyncValue<LastWishesState>> {
  final NotesRepository _repo;
  final String noteId;

  Timer? _debounce;

  LastWishesController({required NotesRepository repo, required this.noteId})
    : _repo = repo,
      super(AsyncValue.data(LastWishesState.initial(noteId))) {
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final loaded = await _load(noteId);
      state = AsyncValue.data(loaded);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  NoteBase _createDraft(String noteId) {
    final now = DateTime.now();
    return NoteBase(
      id: noteId,
      userId: 'userId',
      kind: NoteKind.lastWishes,
      content: '',
      meta: const {},
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }

  LastWishesState _mapNoteToState(
    LastWishesState base,
    NoteBase note, {
    required bool persisted,
  }) {
    final meta = note.meta;

    final enabled = (meta['enabled'] as bool?) ?? false;
    final email = (meta['recipientEmail'] as String?)?.trim() ?? '';
    final years = (meta['waitingYears'] as num?)?.toInt();
    final msg = (meta['messageNote'] as String?) ?? '';

    return base.copyWith(
      loading: false,
      persisted: persisted,
      noteId: note.id,
      note: note,
      content: note.content ?? '',
      email: email,
      confirmEmail: email,
      waitingYears: years,
      messageNote: msg,
      enabled: enabled,
      clearError: true,
    );
  }

  Future<LastWishesState> _load(String noteId) async {
    final base = LastWishesState.initial(noteId);

    final existing = await _repo.getById(noteId);
    if (existing == null ||
        existing.isDeleted ||
        existing.kind != NoteKind.lastWishes) {
      final draft = _createDraft(noteId);
      return _mapNoteToState(base, draft, persisted: false);
    }

    return _mapNoteToState(base, existing, persisted: true);
  }

  Future<void> refreshCurrent() async {
    final cur = state.value ?? LastWishesState.initial(noteId);
    state = AsyncValue.data(cur.copyWith(loading: true, clearError: true));
    try {
      state = AsyncValue.data(await _load(noteId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setContent(String text) {
    final s = state.value;
    final n = s?.note;
    if (s == null || n == null) return;

    final updated = n.copyWith(content: text, isDeleted: false);

    state = AsyncValue.data(
      s.copyWith(note: updated, content: text, clearError: true),
    );

    _scheduleSave();
  }

  void setEmail(String v) {
    final s = state.value;
    if (s == null) return;

    state = AsyncValue.data(s.copyWith(email: v, clearError: true));

    _scheduleSave();
  }

  void setConfirmEmail(String v) {
    final s = state.value;
    if (s == null) return;

    state = AsyncValue.data(s.copyWith(confirmEmail: v, clearError: true));
  }

  void setWaitingYears(int? years) {
    final s = state.value;
    if (s == null) return;

    state = AsyncValue.data(
      s.copyWith(
        waitingYears: years,
        clearWaitingYears: years == null,
        clearError: true,
      ),
    );

    _scheduleSave();
  }

  void setMessageNote(String v) {
    final s = state.value;
    if (s == null) return;

    state = AsyncValue.data(s.copyWith(messageNote: v, clearError: true));

    _scheduleSave();
  }

  bool isValidEmail(String v) {
    final e = v.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      await saveNow();
    });
  }

  Future<void> saveNow() async {
    final s = state.value;
    final n = s?.note;
    if (s == null || n == null || s.saving) return;

    state = AsyncValue.data(s.copyWith(saving: true, clearError: true));

    try {
      final content = s.content.trim();
      final email = s.email.trim();
      final msg = s.messageNote.trim();

      if (content.isEmpty) {
        if (s.persisted) {
          await _repo.markDeleted(n.id);
        }

        state = AsyncValue.data(
          s.copyWith(saving: false, persisted: false, clearError: true),
        );
        return;
      }

      // ✅ 关键：从 repository 再读一次“已持久化”的旧数据
      final persistedNote = await _repo.getById(n.id);

      final persistedMeta = persistedNote?.meta ?? const <String, dynamic>{};
      final oldContent = (persistedNote?.content ?? '').trim();
      final oldEmail =
          (persistedMeta['recipientEmail'] as String?)?.trim() ?? '';
      final oldYears = (persistedMeta['waitingYears'] as num?)?.toInt();
      final oldMsg = (persistedMeta['messageNote'] as String?) ?? '';
      final oldEnabled = (persistedMeta['enabled'] as bool?) ?? false;

      final changed =
          oldContent != content ||
          oldEmail != email ||
          oldYears != s.waitingYears ||
          oldMsg != msg ||
          oldEnabled != s.enabled;

      if (!changed) {
        state = AsyncValue.data(s.copyWith(saving: false, clearError: true));
        return;
      }

      // 用当前 state.note 作为 base，但 updatedAt 现在才真正更新
      final newMeta = <String, dynamic>{
        ...n.meta,
        'recipientEmail': email.isEmpty ? null : email,
        'waitingYears': s.waitingYears,
        'messageNote': msg.isEmpty ? null : msg,
        'enabled': s.enabled,
        'preview': content,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      };

      final updated = n.copyWith(
        kind: NoteKind.lastWishes,
        content: content,
        meta: newMeta,
        updatedAt: DateTime.now(),
        isDeleted: false,
      );

      await _repo.upsert(updated);

      state = AsyncValue.data(
        s.copyWith(
          saving: false,
          persisted: true,
          note: updated,
          content: updated.content ?? '',
          clearError: true,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> confirmEnable() async {
    final s = state.value;
    final n = s?.note;
    if (s == null || n == null) return false;

    if (s.enabled) {
      state = AsyncValue.data(s.copyWith(error: 'Already enabled.'));
      return false;
    }

    if (!s.canConfirm) {
      state = AsyncValue.data(
        s.copyWith(
          error: 'Please complete content / recipient / waiting period.',
        ),
      );
      return false;
    }

    state = AsyncValue.data(s.copyWith(submitting: true, clearError: true));

    try {
      final meta = <String, dynamic>{
        ...n.meta,
        'enabled': true,
        'recipientEmail': s.email.trim(),
        'waitingYears': s.waitingYears,
        'messageNote': s.messageNote.trim().isEmpty
            ? null
            : s.messageNote.trim(),
        'preview': s.content.trim(),
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      };

      final updated = n.copyWith(
        kind: NoteKind.lastWishes,
        content: s.content.trim(),
        meta: meta,
        updatedAt: DateTime.now(),
        isDeleted: false,
      );

      await _repo.upsert(updated);

      state = AsyncValue.data(
        s.copyWith(
          submitting: false,
          note: updated,
          enabled: true,
          persisted: true,
          clearError: true,
        ),
      );
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> disable() async {
    final s = state.value;
    final n = s?.note;
    if (s == null || n == null) return;

    try {
      final meta = <String, dynamic>{
        ...n.meta,
        'enabled': false,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      };

      final updated = n.copyWith(meta: meta, updatedAt: DateTime.now());

      await _repo.upsert(updated);

      state = AsyncValue.data(
        s.copyWith(
          note: updated,
          enabled: false,
          persisted: true,
          clearError: true,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteDraft() async {
    final s = state.value;
    if (s == null) return;

    try {
      await _repo.markDeleted(s.noteId);

      final fresh = _createDraft(s.noteId);
      state = AsyncValue.data(
        _mapNoteToState(
          LastWishesState.initial(s.noteId),
          fresh,
          persisted: false,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
