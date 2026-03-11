// lib/features/future_letter/application/future_letter_draft_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:lifecapsule8_app/features/future_letter/domain/future_letter_draft.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';
import 'package:lifecapsule8_app/features/user/application/user_store.dart';

final futureLetterDraftControllerProvider =
    StateNotifierProvider.family<
      FutureLetterDraftController,
      FutureLetterDraftState,
      String
    >((ref, noteId) => FutureLetterDraftController(ref, noteId));

class FutureLetterDraftState {
  final bool loading;
  final bool saving;
  final bool submitting;
  final String? error;
  final FutureLetterDraft draft;

  const FutureLetterDraftState({
    required this.draft,
    this.loading = false,
    this.saving = false,
    this.submitting = false,
    this.error,
  });

  FutureLetterDraftState copyWith({
    bool? loading,
    bool? saving,
    bool? submitting,
    String? error,
    bool clearError = false,
    FutureLetterDraft? draft,
  }) {
    return FutureLetterDraftState(
      draft: draft ?? this.draft,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
    );
  }

  factory FutureLetterDraftState.initial(String noteId) {
    return FutureLetterDraftState(
      loading: true,
      draft: FutureLetterDraft(
        noteId: noteId,
        content: '',
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class FutureLetterDraftController
    extends StateNotifier<FutureLetterDraftState> {
  final Ref ref;
  final String noteId;

  FutureLetterDraftController(this.ref, this.noteId)
    : super(FutureLetterDraftState.initial(noteId)) {
    _load();
  }

  String get _userId => ref.read(userProvider).currentUser?.userId ?? '';

  Future<void> _load() async {
    try {
      final repo = ref.read(notesRepositoryProvider);
      final note = await repo.getById(noteId);

      if (note == null) {
        final now = DateTime.now();
        state = FutureLetterDraftState(
          loading: false,
          draft: FutureLetterDraft(noteId: noteId, content: '', updatedAt: now),
        );
        return;
      }

      if (note.kind != NoteKind.futureLetter) {
        throw Exception('Future letter note not found: $noteId');
      }

      final meta = Map<String, dynamic>.from(note.meta);

      state = FutureLetterDraftState(
        loading: false,
        draft: FutureLetterDraft(
          noteId: note.id,
          content: note.content ?? '',
          updatedAt: note.updatedAt,
          sendAtIso: (meta['sendAtIso'] as String?)?.trim(),
          userCode: (meta['userCode'] as String?)?.trim(),
          email: (meta['email'] as String?)?.trim(),
          toName: (meta['toName'] as String?)?.trim(),
          fromName: (meta['fromName'] as String?)?.trim(),
        ),
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        saving: false,
        submitting: false,
        error: e.toString(),
      );
    }
  }

  void setContent(String value) {
    state = state.copyWith(
      clearError: true,
      draft: state.draft.copyWith(content: value, updatedAt: DateTime.now()),
    );
  }

  void setSchedule(String? sendAtIso) {
    state = state.copyWith(
      clearError: true,
      draft: state.draft.copyWith(
        sendAtIso: sendAtIso?.trim(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void setRecipient({
    String? userCode,
    String? email,
    String? toName,
    String? fromName,
  }) {
    state = state.copyWith(
      clearError: true,
      draft: state.draft.copyWith(
        userCode: userCode?.trim(),
        email: email?.trim(),
        toName: toName?.trim(),
        fromName: fromName?.trim(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> persist() async {
    if (state.saving) return;

    state = state.copyWith(saving: true, clearError: true);

    try {
      final repo = ref.read(notesRepositoryProvider);
      final existing = await repo.getById(noteId);
      final now = DateTime.now();
      final d = state.draft;

      if (existing == null && _isBlankDraft(d)) {
        state = state.copyWith(saving: false);
        return;
      }

      final meta = Map<String, dynamic>.from(existing?.meta ?? const {});
      meta['kind'] = 'FUTURE_LETTER';
      meta['sendAtIso'] = (d.sendAtIso ?? '').trim();
      meta['userCode'] = (d.userCode ?? '').trim();
      meta['email'] = (d.email ?? '').trim();
      meta['toName'] = (d.toName ?? '').trim();
      meta['fromName'] = (d.fromName ?? '').trim();
      meta['updatedAtMs'] = now.millisecondsSinceEpoch;

      final note =
          existing?.copyWith(
            userId: existing.userId.isNotEmpty ? existing.userId : _userId,
            content: d.content,
            meta: meta,
            updatedAt: now,
            isSynced: false,
            isDeleted: false,
            version: existing.version + 1,
          ) ??
          NoteBase(
            id: noteId,
            userId: _userId,
            kind: NoteKind.futureLetter,
            createdAt: now,
            updatedAt: now,
            content: d.content,
            meta: meta,
            isSynced: false,
            isDeleted: false,
            version: 1,
          );

      await repo.upsert(note);

      state = state.copyWith(
        saving: false,
        draft: state.draft.copyWith(updatedAt: now),
      );
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
    }
  }

  Future<void> confirmAndSend() async {
    if (state.submitting) return;

    final d = state.draft;

    if (d.content.trim().isEmpty) {
      state = state.copyWith(error: 'Content is empty');
      return;
    }
    if (!d.hasRecipient) {
      state = state.copyWith(error: 'Recipient is missing');
      return;
    }
    if ((d.sendAtIso ?? '').trim().isEmpty) {
      state = state.copyWith(error: 'Schedule time is missing');
      return;
    }

    state = state.copyWith(submitting: true, clearError: true);

    try {
      await persist();

      final repo = ref.read(notesRepositoryProvider);
      final existing = await repo.getById(noteId);
      if (existing == null) {
        throw Exception('Future letter note not found: $noteId');
      }

      final now = DateTime.now();
      final meta = Map<String, dynamic>.from(existing.meta);
      meta['sendIntent'] = 'CONFIRMED';
      meta['sendStatus'] = 'PENDING_SYNC';
      meta['confirmedAtMs'] = now.millisecondsSinceEpoch;
      meta['updatedAtMs'] = now.millisecondsSinceEpoch;

      await repo.upsert(
        existing.copyWith(
          meta: meta,
          updatedAt: now,
          isSynced: false,
          version: existing.version + 1,
        ),
      );

      state = state.copyWith(
        submitting: false,
        draft: state.draft.copyWith(updatedAt: now),
      );
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> reload() async {
    state = state.copyWith(loading: true, clearError: true);
    await _load();
  }

  bool _isBlankDraft(FutureLetterDraft d) {
    final content = d.content.trim();
    final sendAtIso = (d.sendAtIso ?? '').trim();
    final userCode = (d.userCode ?? '').trim();
    final email = (d.email ?? '').trim();
    final toName = (d.toName ?? '').trim();
    final fromName = (d.fromName ?? '').trim();

    return content.isEmpty &&
        sendAtIso.isEmpty &&
        userCode.isEmpty &&
        email.isEmpty &&
        toName.isEmpty &&
        fromName.isEmpty;
  }
}
