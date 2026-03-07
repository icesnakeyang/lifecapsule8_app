import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final lastWishesRecipientControllerProvider =
    AsyncNotifierProvider<
      LastWishesRecipientController,
      LastWishesRecipientState
    >(LastWishesRecipientController.new);

class LastWishesRecipientState {
  final bool loading;
  final bool saving;
  final bool persisted;
  final String? error;

  final NoteBase? note;

  /// recipient 相关字段（来自 note.meta）
  final String email;
  final String confirmEmail;
  final int? waitingYears;
  final String messageNote;

  const LastWishesRecipientState({
    this.loading = true,
    this.saving = false,
    this.persisted = false,
    this.error,
    this.note,
    this.email = '',
    this.confirmEmail = '',
    this.waitingYears,
    this.messageNote = '',
  });

  LastWishesRecipientState copyWith({
    bool? loading,
    bool? saving,
    bool? persisted,
    String? error,
    bool clearError = false,
    NoteBase? note,
    String? email,
    String? confirmEmail,
    int? waitingYears,
    bool clearWaitingYears = false,
    String? messageNote,
  }) {
    return LastWishesRecipientState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      persisted: persisted ?? this.persisted,
      error: clearError ? null : (error ?? this.error),
      note: note ?? this.note,
      email: email ?? this.email,
      confirmEmail: confirmEmail ?? this.confirmEmail,
      waitingYears: clearWaitingYears
          ? null
          : (waitingYears ?? this.waitingYears),
      messageNote: messageNote ?? this.messageNote,
    );
  }
}

class LastWishesRecipientController
    extends AsyncNotifier<LastWishesRecipientState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  static const String _noteId = 'last_wishes';
  Timer? _debounce;

  @override
  Future<LastWishesRecipientState> build() async {
    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
    });

    final base = const LastWishesRecipientState(loading: true);

    try {
      final n = await _repo.getById(_noteId);

      // 如果 note 还不存在（用户没走 edit / 或 edit 未落盘），这里也给一个内存草稿
      final now = DateTime.now();
      final note = (n != null && n.isDeleted != true)
          ? n
          : NoteBase(
              id: _noteId,
              userId: 'userId',
              kind: NoteKind.lastWishes, // 你需要在 NoteKind 里加 lastWishes
              content: '',
              meta: const {},
              createdAt: now,
              updatedAt: now,
              isDeleted: false,
            );

      final meta = (note.meta ?? const <String, dynamic>{});

      final email = (meta['recipientEmail'] as String?)?.trim() ?? '';
      final years = (meta['waitingYears'] as num?)?.toInt();
      final noteMsg = (meta['messageNote'] as String?) ?? '';

      return base.copyWith(
        loading: false,
        persisted: n != null && n.isDeleted != true,
        note: note,
        email: email,
        confirmEmail: email,
        waitingYears: years,
        messageNote: noteMsg,
        clearError: true,
      );
    } catch (e) {
      return base.copyWith(loading: false, error: e.toString());
    }
  }

  // ---------------- UI setters ----------------

  void setEmail(String v) {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(email: v, clearError: true));
  }

  void setConfirmEmail(String v) {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(confirmEmail: v, clearError: true));
  }

  void setWaitingYears(int? years) {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(
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
    state = AsyncData(s.copyWith(messageNote: v, clearError: true));
    _scheduleSave();
  }

  // ---------------- validation helpers ----------------

  bool get canGoNext {
    final s = state.value;
    if (s == null) return false;
    if (!isValidEmail(s.email)) return false;
    if (s.email.trim() != s.confirmEmail.trim()) return false;
    if (s.waitingYears == null) return false;
    if (!const [1, 5, 10, 20].contains(s.waitingYears)) return false;
    return true;
  }

  bool isValidEmail(String v) {
    final e = v.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  // ---------------- save ----------------

  Future<void> saveNow() async {
    final s = state.value;
    if (s == null) return;
    final n = s.note;
    if (n == null) return;
    if (s.saving) return;

    state = AsyncData(s.copyWith(saving: true, clearError: true));

    try {
      final email = s.email.trim();
      final years = s.waitingYears;
      final msg = s.messageNote.trim();

      final newMeta = <String, dynamic>{
        ...(n.meta ?? const <String, dynamic>{}),
        'recipientEmail': email.isEmpty ? null : email,
        'waitingYears': years,
        'messageNote': msg.isEmpty ? null : msg,
      };

      final updated = n.copyWith(
        kind: NoteKind.lastWishes,
        meta: newMeta,
        updatedAt: DateTime.now(),
        isDeleted: false,
      );

      await _repo.upsert(updated);

      state = AsyncData(
        (state.value ?? s).copyWith(
          saving: false,
          persisted: true,
          note: updated,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? s).copyWith(saving: false, error: e.toString()),
      );
    }
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      await saveNow();
    });
  }
}
