import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/future_letter/appication/future_letter_draft_store.dart';

import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';
import 'package:lifecapsule8_app/features/user/application/user_store.dart';

final futureLetterPreviewControllerProvider =
    AsyncNotifierProvider<
      FutureLetterPreviewController,
      FutureLetterPreviewState
    >(FutureLetterPreviewController.new);

class FutureLetterPreviewState {
  final bool loading;
  final bool submitting;
  final String? error;

  // snapshot for UI
  final String scheduleText;
  final String recipientText;
  final String namesText;
  final String contentText;

  const FutureLetterPreviewState({
    this.loading = true,
    this.submitting = false,
    this.error,
    this.scheduleText = '-',
    this.recipientText = '-',
    this.namesText = '-',
    this.contentText = '',
  });

  FutureLetterPreviewState copyWith({
    bool? loading,
    bool? submitting,
    String? error,
    bool clearError = false,
    String? scheduleText,
    String? recipientText,
    String? namesText,
    String? contentText,
  }) {
    return FutureLetterPreviewState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
      scheduleText: scheduleText ?? this.scheduleText,
      recipientText: recipientText ?? this.recipientText,
      namesText: namesText ?? this.namesText,
      contentText: contentText ?? this.contentText,
    );
  }
}

class FutureLetterPreviewController
    extends AsyncNotifier<FutureLetterPreviewState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  // ⚠️ 这里换成你项目真实的 userId provider
  String get _userId {
    return ref.read(userProvider).currentUser?.userId ?? '';
  }

  @override
  Future<FutureLetterPreviewState> build() async {
    // 关键：监听 current 变化，Preview snapshot 自动刷新
    final d = ref.watch(futureLetterDraftStoreProvider).current;

    if (d == null) {
      return const FutureLetterPreviewState(
        loading: false,
        error: 'No current draft',
      );
    }

    final scheduleText = () {
      final iso = (d.sendAtIso ?? '').trim();
      if (iso.isEmpty) return '-';
      final utc = DateTime.tryParse(iso);
      if (utc == null) return iso;
      return utc.toLocal().toString(); // 你可替换成 formatLocalDateTime(...)
    }();

    final recipientText = () {
      final userCode = (d.userCode ?? '').trim();
      final email = (d.email ?? '').trim();
      if (userCode.isEmpty && email.isEmpty) return '-';
      if (userCode.isNotEmpty && email.isNotEmpty) {
        return 'UserCode: $userCode\nEmail: $email';
      }
      if (userCode.isNotEmpty) return 'UserCode: $userCode';
      return 'Email: $email';
    }();

    final toName = (d.toName ?? '').trim();
    final fromName = (d.fromName ?? '').trim();
    final namesText =
        'To: ${toName.isEmpty ? '-' : toName}\nFrom: ${fromName.isEmpty ? '-' : fromName}';

    final contentText = d.content.trim();

    return FutureLetterPreviewState(
      loading: false,
      scheduleText: scheduleText,
      recipientText: recipientText,
      namesText: namesText,
      contentText: contentText,
    );
  }

  Future<void> persistBeforeLeave() async {
    final d = ref.read(futureLetterDraftStoreProvider).current;
    if (d == null) return;
    await _persistDraftToNotes(d, confirmed: false);
  }

  Future<void> confirmAndSend() async {
    final s = state.value ?? const FutureLetterPreviewState(loading: false);
    if (s.submitting) return;

    state = AsyncData(s.copyWith(submitting: true, clearError: true));

    try {
      final d = ref.read(futureLetterDraftStoreProvider).current;
      if (d == null) throw Exception('No current draft');

      // ✅ 校验
      if (d.content.trim().isEmpty) throw Exception('Content is empty');

      final hasRecipient =
          (d.userCode ?? '').trim().isNotEmpty ||
          (d.email ?? '').trim().isNotEmpty;
      if (!hasRecipient) throw Exception('Recipient is missing');

      final sendAtIso = (d.sendAtIso ?? '').trim();
      if (sendAtIso.isEmpty) throw Exception('Schedule time is missing');

      // ✅ 1) persist notes_box + 云端（通过 NotesRepository）
      await _persistDraftToNotes(d, confirmed: true);

      // ✅ 3) 发送成功：清 current（Store 只做状态变更）
      ref.read(futureLetterDraftStoreProvider.notifier).clearCurrent();

      state = AsyncData(
        (state.value ?? s).copyWith(submitting: false, clearError: true),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? s).copyWith(submitting: false, error: e.toString()),
      );
      rethrow;
    }
  }

  Future<void> _persistDraftToNotes(
    dynamic d, {
    required bool confirmed,
  }) async {
    final content = d.content.trim();
    if (content.isEmpty) return;

    final meta = <String, dynamic>{
      'kind': 'FUTURE_LETTER',
      if ((d.userCode ?? '').trim().isNotEmpty) 'userCode': d.userCode,
      if ((d.userId ?? '').trim().isNotEmpty) 'userId': d.userId,
      if ((d.nickname ?? '').trim().isNotEmpty) 'nickname': d.nickname,
      if ((d.email ?? '').trim().isNotEmpty) 'email': d.email,
      if ((d.toName ?? '').trim().isNotEmpty) 'toName': d.toName,
      if ((d.fromName ?? '').trim().isNotEmpty) 'fromName': d.fromName,
      if ((d.sendAtIso ?? '').trim().isNotEmpty) 'sendAtIso': d.sendAtIso,
      if (confirmed) 'sendIntent': 'CONFIRMED',
      if (confirmed) 'sendStatus': 'PENDING_SYNC',
      if (confirmed) 'confirmedAtMs': DateTime.now().millisecondsSinceEpoch,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    };

    final existing = await _repo.getById(d.noteId);
    final now = DateTime.now();

    await _repo.upsert(
      NoteBase(
        id: d.noteId,
        userId: _userId,
        kind: NoteKind.futureLetter,
        content: content,
        meta: meta,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        isDeleted: false,
      ),
    );
  }
}
