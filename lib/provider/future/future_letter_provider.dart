// lib/provider/future/future_letter_provider.dart
// ✅ Future 模块自己保存 draft（recipient/send 配置）到 future_box
// ✅ 但只要 content 非空并落盘，就调用 noteProvider.upsertBusinessNote 把“内容”同步到云端 note_base/content

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:lifecapsule8_app/hive/hive_boxes.dart';
import 'package:lifecapsule8_app/provider/future/future_letter_draft.dart';
import 'package:lifecapsule8_app/provider/future/future_letter_state.dart';
import 'package:lifecapsule8_app/provider/note/note_provider.dart';
import 'package:lifecapsule8_app/provider/send_task/send_task_model.dart';
import 'package:lifecapsule8_app/provider/send_task/send_task_notifier.dart';

final futureLetterProvider =
    NotifierProvider<FutureLetterNotifier, FutureLetterState>(
      FutureLetterNotifier.new,
    );

class FutureLetterNotifier extends Notifier<FutureLetterState> {
  late final Box<String> _box = Hive.box<String>(HiveBoxes.futureBox);
  bool _persisting = false;
  String? _lastPersistedSig;
  @override
  FutureLetterState build() {
    final list = _loadAllFromHive();
    return FutureLetterState(
      currentFutureLetter: null,
      futureLetterList: list,
      loading: false,
      errMsg: null,
    );
  }

  String _sigOf(FutureLetterDraft d) {
    // 只要内容/收件人/时间这些你关心的改变，就认为需要再 persist
    return [
      d.noteId,
      d.content.trim(),
      (d.email ?? '').trim(),
      (d.toName ?? '').trim(),
      (d.fromName ?? '').trim(),
      (d.sendAtIso ?? '').trim(),
    ].join('|');
  }

  Future<void> persistCurrentIfNeeded() async {
    final cur = state.currentFutureLetter;
    if (cur == null) return;

    final content = cur.content.trim();
    if (content.isEmpty) return;

    final sig = _sigOf(cur);
    if (_lastPersistedSig == sig) return; // ✅ 防重复（Next + Exit 连续触发）

    if (_persisting) return;
    _persisting = true;
    try {
      await _upsertToHive(
        cur,
      ); // ✅ future_box + noteProvider.upsertBusinessNote(...)
      _lastPersistedSig = sig;
      _reloadListKeepCurrent();
    } finally {
      _persisting = false;
    }
  }

  /// 输入时只更新内存（不落盘）
  void setCurrentContentInMemory(String content) {
    final cur = state.currentFutureLetter;
    if (cur == null) return;
    state = state.copyWith(
      currentFutureLetter: cur.copyWith(
        updatedAt: DateTime.now(),
        content: content,
      ),
    );
  }

  List<FutureLetterDraft> _loadAllFromHive() {
    final list = <FutureLetterDraft>[];
    for (final k in _box.keys) {
      final noteId = k.toString();
      final raw = _box.get(noteId);
      if (raw == null || raw.isEmpty) continue;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final d = FutureLetterDraft.fromJson(map);
        if (d.noteId.isNotEmpty) list.add(d);
      } catch (_) {}
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<void> _upsertToHive(FutureLetterDraft d) async {
    await _box.put(d.noteId, jsonEncode(d.toJson()));

    // ✅ 内容非空：把“内容”写入 noteProvider（触发自动同步到云端）
    if (d.content.trim().isNotEmpty) {
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

      await ref
          .read(noteProvider.notifier)
          .upsertBusinessNote(
            noteId: d.noteId,
            noteType: 'FUTURE_LETTER',
            plainText: d.content,
            meta: meta,
          );
    }
  }

  void _reloadListKeepCurrent() {
    final list = _loadAllFromHive();
    FutureLetterDraft? cur = state.currentFutureLetter;
    if (cur != null) {
      final latest = list.where((e) => e.noteId == cur!.noteId).toList();
      cur = latest.isEmpty ? null : latest.first;
    }
    state = state.copyWith(futureLetterList: list, currentFutureLetter: cur);
  }

  String _genNoteId() => 'future_${DateTime.now().microsecondsSinceEpoch}';

  Future<FutureLetterDraft> createAndSelectDraft() async {
    final noteId = _genNoteId();
    final d = FutureLetterDraft(
      noteId: noteId,
      updatedAt: DateTime.now(),
      content: '',
    );
    await _box.put(d.noteId, jsonEncode(d.toJson()));
    state = state.copyWith(currentFutureLetter: d);
    _reloadListKeepCurrent();
    return d;
  }

  Future<void> persistCurrent() async {
    final cur = state.currentFutureLetter;
    if (cur == null) return;
    await _upsertToHive(cur);
    _reloadListKeepCurrent();
  }

  FutureLetterDraft ensureCurrentDraft() {
    final cur = state.currentFutureLetter;
    if (cur != null) return cur;

    final now = DateTime.now();
    final d = FutureLetterDraft(
      noteId: _genNoteId(),
      content: '',
      updatedAt: now,
    );

    state = state.copyWith(currentFutureLetter: d);
    return d;
  }

  void setCurrentByNoteId(String noteId) {
    final hit = state.futureLetterList
        .where((e) => e.noteId == noteId)
        .toList();
    if (hit.isEmpty) return;
    state = state.copyWith(currentFutureLetter: hit.first);
  }

  Future<void> deleteCurrent() async {
    final cur = state.currentFutureLetter;
    if (cur == null) return;

    await _box.delete(cur.noteId);

    // current 清掉，列表刷新
    state = state.copyWith(clearCurrentFutureLetter: true);
    _reloadListKeepCurrent();
  }

  Future<void> setSendAtInMemory({required DateTime sendAtLocal}) async {
    final cur = state.currentFutureLetter;
    if (cur == null) return;

    // 统一存 UTC ISO（你前面已经在用这个规则）
    final isoUtc = sendAtLocal.toUtc().toIso8601String();

    state = state.copyWith(
      currentFutureLetter: cur.copyWith(
        sendAtIso: isoUtc,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setRecipientInMemory({
    String? userCode,
    String? email,
    String? toName,
    String? fromName,
  }) async {
    final cur = state.currentFutureLetter;
    if (cur == null) return;

    state = state.copyWith(
      currentFutureLetter: cur.copyWith(
        userCode: userCode,
        email: email,
        toName: toName,
        fromName: fromName,
        updatedAt: DateTime.now(),
      ),
    );
  }

  // 放到 FutureLetterNotifier 类体内：
  Future<void> confirmSendCurrent() async {
    final cur = state.currentFutureLetter;
    if (cur == null) {
      state = state.copyWith(errMsg: 'No current future letter');
      return;
    }

    // ✅ 基本校验
    if (cur.content.trim().isEmpty) {
      state = state.copyWith(errMsg: 'Content is empty');
      return;
    }
    final hasRecipient =
        (cur.userCode ?? '').trim().isNotEmpty ||
        (cur.email ?? '').trim().isNotEmpty;
    if (!hasRecipient) {
      state = state.copyWith(errMsg: 'Recipient is missing');
      return;
    }
    final sendAtIso = (cur.sendAtIso ?? '').trim();
    if (sendAtIso.isEmpty) {
      state = state.copyWith(errMsg: 'Schedule time is missing');
      return;
    }

    // ✅ 1) 确保已落盘 future_box + 内容同步到 note_base/content
    await persistCurrentIfNeeded();

    // 2) enqueue send_task（本地入队）
    final recipient = RecipientPayload(
      userCode: (cur.userCode ?? '').trim().isEmpty
          ? null
          : cur.userCode!.trim(),
      email: (cur.email ?? '').trim().isEmpty ? null : cur.email!.trim(),
      self: false,
    );

    // 幂等键：同一封信 + 同一收件人 + 同一时间 => 同一任务
    final idemKey = [
      SendTaskType.future.name,
      cur.noteId,
      SendScheduleType.atTime.name,
      recipient.userCode ?? '',
      recipient.email ?? '',
      sendAtIso,
    ].join('|');

    try {
      await ref
          .read(sendTaskProvider.notifier)
          .enqueue(
            type: SendTaskType.future,
            scheduleType: SendScheduleType.atTime,
            scheduleAtIso: sendAtIso,
            recipient: recipient,
            payloadRef: cur.noteId,
            cryptoMode: CryptoMode.none,
            idemKey: idemKey,
          );

      state = state.copyWith(clearCurrentFutureLetter: true, clearErrMsg: true);
    } catch (e) {
      state = state.copyWith(errMsg: 'Failed to enqueue send task');
      rethrow;
    }
  }

  void clearCurrentDraft() {
    state = state.copyWith(clearCurrentFutureLetter: true);
  }

  FutureLetterDraft startNewDraft() {
    final now = DateTime.now();
    final d = FutureLetterDraft(
      noteId: _genNoteId(),
      content: '',
      updatedAt: now,
    );
    // ✅ 重置去重签名，确保新 draft 的 persist 不会被挡
    _lastPersistedSig = null;

    state = state.copyWith(currentFutureLetter: d, clearErrMsg: true);
    return d;
  }
}
