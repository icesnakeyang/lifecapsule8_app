import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final futureLetterRecipientControllerProvider =
    AsyncNotifierProvider<
      FutureLetterRecipientController,
      FutureLetterRecipientState
    >(FutureLetterRecipientController.new);

class FutureLetterRecipientState {
  final bool loading;
  final bool saving;
  final String? error;

  final String userCode;
  final String email;
  final String toName;
  final String fromName;

  const FutureLetterRecipientState({
    this.loading = true,
    this.saving = false,
    this.error,
    this.userCode = '',
    this.email = '',
    this.toName = '',
    this.fromName = '',
  });

  FutureLetterRecipientState copyWith({
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
    String? userCode,
    String? email,
    String? toName,
    String? fromName,
  }) {
    return FutureLetterRecipientState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      userCode: userCode ?? this.userCode,
      email: email ?? this.email,
      toName: toName ?? this.toName,
      fromName: fromName ?? this.fromName,
    );
  }

  bool get hasRecipient =>
      userCode.trim().isNotEmpty || email.trim().isNotEmpty;
}

class FutureLetterRecipientController
    extends AsyncNotifier<FutureLetterRecipientState> {
  @override
  Future<FutureLetterRecipientState> build() async {
    return const FutureLetterRecipientState(loading: true);
  }

  Future<void> open({required String noteId}) async {
    state = AsyncData(
      (state.value ?? const FutureLetterRecipientState()).copyWith(
        loading: true,
        clearError: true,
      ),
    );

    try {
      final repo = ref.read(notesRepositoryProvider);
      final note = await repo.getById(noteId);

      if (note == null || note.kind != NoteKind.futureLetter) {
        throw Exception('Future letter not found: $noteId');
      }

      final meta = note.meta;
      state = AsyncData(
        FutureLetterRecipientState(
          loading: false,
          userCode: (meta['userCode'] as String?)?.trim() ?? '',
          email: (meta['email'] as String?)?.trim() ?? '',
          toName: (meta['toName'] as String?)?.trim() ?? '',
          fromName: (meta['fromName'] as String?)?.trim() ?? '',
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? const FutureLetterRecipientState()).copyWith(
          loading: false,
          error: e.toString(),
        ),
      );
    }
  }

  void setUserCode(String v) {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(userCode: v, clearError: true));
  }

  void setEmail(String v) {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(email: v, clearError: true));
  }

  void setToName(String v) {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(toName: v, clearError: true));
  }

  void setFromName(String v) {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(fromName: v, clearError: true));
  }

  bool get canNext {
    final s = state.value;
    if (s == null) return false;
    return s.hasRecipient && !s.saving;
  }

  Future<void> persistBeforeLeave({required String noteId}) async {
    final s = state.value;
    if (s == null) return;
    if (s.saving) return;

    state = AsyncData(s.copyWith(saving: true, clearError: true));

    try {
      final repo = ref.read(notesRepositoryProvider);
      final note = await repo.getById(noteId);
      if (note == null || note.kind != NoteKind.futureLetter) {
        throw Exception('Future letter note found: $noteId');
      }

      final now = DateTime.now();
      final meta = Map<String, dynamic>.from(note.meta);
      meta['userCode'] = s.userCode.trim();
      meta['email'] = s.email.trim();
      meta['toName'] = s.toName.trim();
      meta['fromName'] = s.fromName.trim();
      meta['updatedAtMs'] = now.millisecondsSinceEpoch;

      await repo.upsert(
        note.copyWith(
          meta: meta,
          updatedAt: now,
          isSynced: false,
          version: note.version + 1,
        ),
      );

      state = AsyncData((state.value ?? s).copyWith(saving: false));
    } catch (e) {
      final latest = state.value ?? s;
      state = AsyncData(latest.copyWith(saving: false, error: e.toString()));
    }
  }
}
