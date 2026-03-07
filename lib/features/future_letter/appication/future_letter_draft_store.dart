// lib/features/future_letter/application/future_letter_draft_store.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/future_letter/appication/future_letter_draft_store_state.dart';

import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

import 'package:lifecapsule8_app/features/future_letter/domain/future_letter_draft.dart';

final futureLetterDraftStoreProvider =
    NotifierProvider<FutureLetterDraftStore, FutureLetterDraftStoreState>(
      FutureLetterDraftStore.new,
    );

class FutureLetterDraftStore extends Notifier<FutureLetterDraftStoreState> {
  // ✅ 这里 ref 才存在（Notifier 的成员）
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  // ⚠️ 换成你真实的 userId provider（这里只是兜底）
  String get _userId => 'userId';

  @override
  FutureLetterDraftStoreState build() {
    return FutureLetterDraftStoreState.initial();
  }

  void setList(List<FutureLetterDraft> list) {
    final cur = state.current;
    FutureLetterDraft? newCur = cur;
    if (cur != null) {
      final hit = list.where((e) => e.noteId == cur.noteId).toList();
      newCur = hit.isEmpty ? null : hit.first;
    }
    state = state.copyWith(
      list: list,
      current: newCur,
      clearCurrent: newCur == null,
    );
  }

  void setCurrentInMemory(FutureLetterDraft? d) {
    state = state.copyWith(current: d);
  }

  void clearCurrent() {
    state = state.copyWith(clearCurrent: true);
  }

  /// Schedule：写入 draft（内存）
  void setSendAtLocalInMemory(DateTime local) {
    final cur = state.current;
    if (cur == null) return;

    final isoUtc = local.toUtc().toIso8601String();

    state = state.copyWith(
      current: cur.copyWith(sendAtIso: isoUtc, updatedAt: DateTime.now()),
    );
  }

  // ----------------- 你要补的：Recipient -----------------

  void setRecipientInMemory({
    String? userCode,
    String? email,
    String? toName,
    String? fromName,
  }) {
    final cur = state.current;
    if (cur == null) return;

    state = state.copyWith(
      current: cur.copyWith(
        userCode: userCode,
        email: email,
        toName: toName,
        fromName: fromName,
        updatedAt: DateTime.now(),
      ),
    );
  }

  // Content：写入 draft（内存）——给 write controller 用
  void setContentInMemory(String text) {
    final cur = state.current;
    if (cur == null) return;

    state = state.copyWith(
      current: cur.copyWith(content: text, updatedAt: DateTime.now()),
    );
  }

  // ----------------- 你要补的：Persist -----------------

  Future<void> persistNowIfNeeded() async {
    final d = state.current;
    if (d == null) return;

    final content = (d.content).trim();
    final sendAtIso = (d.sendAtIso ?? '').trim();
    final userCode = (d.userCode ?? '').trim();
    final email = (d.email ?? '').trim();
    final toName = (d.toName ?? '').trim();
    final fromName = (d.fromName ?? '').trim();

    // ✅ 只要用户填了任何一项（包括 sendAt），就保存草稿
    final hasAnything =
        content.isNotEmpty ||
        sendAtIso.isNotEmpty ||
        userCode.isNotEmpty ||
        email.isNotEmpty ||
        toName.isNotEmpty ||
        fromName.isNotEmpty;

    if (!hasAnything) return;

    final meta = <String, dynamic>{
      'kind': 'FUTURE_LETTER',
      if ((d.userCode ?? '').trim().isNotEmpty) 'userCode': d.userCode,
      if ((d.userId ?? '').trim().isNotEmpty) 'userId': d.userId,
      if ((d.nickname ?? '').trim().isNotEmpty) 'nickname': d.nickname,
      if ((d.email ?? '').trim().isNotEmpty) 'email': d.email,
      if ((d.toName ?? '').trim().isNotEmpty) 'toName': d.toName,
      if ((d.fromName ?? '').trim().isNotEmpty) 'fromName': d.fromName,
      if ((d.sendAtIso ?? '').trim().isNotEmpty) 'sendAtIso': d.sendAtIso,
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

    // 刷新 UI 的 updatedAt
    state = state.copyWith(current: d.copyWith(updatedAt: now));
  }

  /// 发送成功后清掉 current（给 preview controller 用）
  Future<void> clearCurrentDraft() async {
    state = state.copyWith(clearCurrent: true);
  }

  String startNewDraft() {
    final newId = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now();

    final d = FutureLetterDraft(
      noteId: newId,
      content: '',
      updatedAt: now,

      // 其他字段按你 FutureLetterDraft 的定义补齐（如果有的话）
      // userCode: null,
      // userId: null,
      // nickname: null,
      // email: null,
      // toName: null,
      // fromName: null,
      // sendAtIso: null,
    );

    // ✅ 设为 current（并可选：放进 list 顶部，立刻在列表可见）
    state = state.copyWith(list: [d, ...state.list], current: d);

    return newId;
  }
}
