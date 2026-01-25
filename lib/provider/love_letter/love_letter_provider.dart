// ✅ 你这份 love_letter_provider.dart 里有两个“致命问题”：
// 1) deleteDraft(String noteId) 定义了两次（会直接编译报错）
// 2) import 了 LoveSendTaskBuilder / sendTaskProvider，但你贴的文件顶部没有用到 dt_localized 之外的东西？（confirmSend 用到了 builder，所以 ok）
//
// 我给你一份“只修复涉及到的功能”的版本：
// - 去掉重复的 deleteDraft（保留一个）
// - 保留你现有所有方法与逻辑不动
// - 其它不改

// lib/provider/love_letter/love_letter_provider.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:lifecapsule8_app/hive/hive_boxes.dart';
import 'package:lifecapsule8_app/provider/love_letter/love_letter_draft.dart';
import 'package:lifecapsule8_app/provider/love_letter/love_letter_state.dart';
import 'package:lifecapsule8_app/provider/send_task/builders/love_send_task_builder.dart';
import 'package:lifecapsule8_app/provider/send_task/send_task_notifier.dart';
import 'package:lifecapsule8_app/utils/dt_localized.dart';

final loveLetterProvider =
    NotifierProvider<LoveLetterNotifier, LoveLetterState>(() {
      return LoveLetterNotifier();
    });

class LoveLetterNotifier extends Notifier<LoveLetterState> {
  late final Box _draftBox = Hive.box(HiveBoxes.loveLetterDrafts);
  static const String _kCurrentNoteId = '__current_note_id__';

  @override
  LoveLetterState build() {
    final drafts = <String, LoveLetterDraft>{};
    for (final k in _draftBox.keys) {
      final key = k.toString();
      if (key == _kCurrentNoteId) continue;

      final raw = _draftBox.get(key);
      if (raw == null) continue;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final d = LoveLetterDraft.fromJson(map);
        if (d.noteId.isNotEmpty) drafts[d.noteId] = d;
      } catch (_) {}
    }

    LoveLetterDraft? current;
    final curId = _draftBox.get(_kCurrentNoteId)?.toString();
    if (curId != null && curId.isNotEmpty) {
      current = drafts[curId];
    }

    return LoveLetterState(draftsByNoteId: drafts, currentDraft: current);
  }

  Future<String> ensureCurrentNoteId() async {
    final existing = _draftBox.get(_kCurrentNoteId)?.toString();
    if (existing != null && existing.trim().isNotEmpty) return existing;

    final id = 'love_${DateTime.now().microsecondsSinceEpoch}';
    await _draftBox.put(_kCurrentNoteId, id);
    return id;
  }

  Future<void> setCurrentNoteId(String noteId) async {
    await _draftBox.put(_kCurrentNoteId, noteId);
    setCurrentDraft(noteId);
  }

  LoveLetterDraft? getDraft(String noteId) => state.draftsByNoteId[noteId];

  void setCurrentDraft(String noteId) {
    state = state.copyWith(currentDraft: state.draftsByNoteId[noteId]);
  }

  void clearCurrentDraft() {
    state = state.copyWith(clearCurrentDraft: true);
  }

  Future<LoveLetterDraft> ensureDraft(String noteId) async {
    final existing = state.draftsByNoteId[noteId];
    if (existing != null) {
      return existing;
    }

    final created = LoveLetterDraft(noteId: noteId, updatedAt: DateTime.now());
    await _draftBox.put(noteId, jsonEncode(created.toJson()));

    final newMap = {...state.draftsByNoteId, noteId: created};
    state = state.copyWith(draftsByNoteId: newMap);
    return created;
  }

  Future<void> saveContent({
    required String noteId,
    required String content,
  }) async {
    final base =
        state.draftsByNoteId[noteId] ??
        LoveLetterDraft(noteId: noteId, updatedAt: DateTime.now());

    final next = base.copyWith(updatedAt: DateTime.now(), content: content);

    await _draftBox.put(noteId, jsonEncode(next.toJson()));

    state = state.copyWith(
      draftsByNoteId: {...state.draftsByNoteId, noteId: next},
      currentDraft: next,
    );
  }

  Future<void> saveRecipient({
    required String noteId,
    required String toType,
    String? userCode,
    String? userId,
    String? nickname,
    String? email,
    String? toName,
    String? fromName,
    bool clearEmail = false,
    bool clearToName = false,
    bool clearFromName = false,
  }) async {
    final base =
        state.draftsByNoteId[noteId] ??
        LoveLetterDraft(noteId: noteId, updatedAt: DateTime.now());

    final next = base.copyWith(
      updatedAt: DateTime.now(),
      toType: toType,
      userCode: userCode,
      userId: userId,
      nickname: nickname,
      email: email,
      toName: toName,
      fromName: fromName,
      clearRecipient: false,
      clearEmail: clearEmail,
      clearToName: clearToName,
      clearFromName: clearFromName,
    );

    await _draftBox.put(noteId, jsonEncode(next.toJson()));

    final newMap = {...state.draftsByNoteId, noteId: next};
    state = state.copyWith(draftsByNoteId: newMap, currentDraft: next);
  }

  Future<void> clearRecipient(String noteId) async {
    final base = state.draftsByNoteId[noteId];
    if (base == null) return;

    final next = base.copyWith(updatedAt: DateTime.now(), clearRecipient: true);

    await _draftBox.put(noteId, jsonEncode(next.toJson()));

    final newMap = {...state.draftsByNoteId, noteId: next};
    state = state.copyWith(draftsByNoteId: newMap, currentDraft: next);
  }

  Future<void> saveSendAt({
    required String noteId,
    required DateTime sendAtLocal,
  }) async {
    final base =
        state.draftsByNoteId[noteId] ??
        LoveLetterDraft(noteId: noteId, updatedAt: DateTime.now());

    final next = base.copyWith(
      updatedAt: DateTime.now(),
      sendAtIso: toIso8601WithOffset(sendAtLocal),
      clearSendAt: false,
    );

    await _draftBox.put(noteId, jsonEncode(next.toJson()));

    final newMap = {...state.draftsByNoteId, noteId: next};
    state = state.copyWith(draftsByNoteId: newMap, currentDraft: next);
  }

  Future<void> clearSendAt(String noteId) async {
    final base = state.draftsByNoteId[noteId];
    if (base == null) return;

    final next = base.copyWith(updatedAt: DateTime.now(), clearSendAt: true);

    await _draftBox.put(noteId, jsonEncode(next.toJson()));

    final newMap = {...state.draftsByNoteId, noteId: next};
    state = state.copyWith(draftsByNoteId: newMap, currentDraft: next);
  }

  /// ✅ 只保留一个 deleteDraft（你文件里重复定义了两次）
  Future<void> deleteDraft(String noteId) async {
    await _draftBox.delete(noteId);

    final newMap = {...state.draftsByNoteId}..remove(noteId);

    state = state.copyWith(draftsByNoteId: newMap);
  }

  Future<void> saveOrDeleteDraft({
    required String noteId,
    required String content,
  }) async {
    final c = content.trim();
    if (c.isEmpty) {
      await deleteDraft(noteId);

      final cur = _draftBox.get(_kCurrentNoteId)?.toString();
      if (cur == noteId) {
        await _draftBox.delete(_kCurrentNoteId);
        state = state.copyWith(clearCurrentDraft: true);
      }
      return;
    }
    await saveContent(noteId: noteId, content: content);
  }

  Future<void> saveSendMode({
    required String noteId,
    required String mode,
  }) async {
    final base =
        state.draftsByNoteId[noteId] ??
        LoveLetterDraft(noteId: noteId, updatedAt: DateTime.now());

    final next = base.copyWith(
      updatedAt: DateTime.now(),
      sendMode: mode,
      clearSendMode: false,
    );

    await _draftBox.put(noteId, jsonEncode(next.toJson()));
    state = state.copyWith(
      draftsByNoteId: {...state.draftsByNoteId, noteId: next},
      currentDraft: next,
    );
  }

  Future<void> clearSendMode(String noteId) async {
    final base = state.draftsByNoteId[noteId];
    if (base == null) return;

    final next = base.copyWith(updatedAt: DateTime.now(), clearSendMode: true);

    await _draftBox.put(noteId, jsonEncode(next.toJson()));
    state = state.copyWith(
      draftsByNoteId: {...state.draftsByNoteId, noteId: next},
      currentDraft: next,
    );
  }

  Future<void> savePasscode({
    required String noteId,
    required String mode,
    String? passcode,
    bool clearPasscode = false,
  }) async {
    final base =
        state.draftsByNoteId[noteId] ??
        LoveLetterDraft(noteId: noteId, updatedAt: DateTime.now());

    final next = base.copyWith(
      updatedAt: DateTime.now(),
      passcodeMode: mode,
      passcode: passcode,
      clearPasscode: clearPasscode,
    );

    await _draftBox.put(noteId, jsonEncode(next.toJson()));

    state = state.copyWith(
      draftsByNoteId: {...state.draftsByNoteId, noteId: next},
      currentDraft: next,
    );
  }

  Future<void> clearPasscode(String noteId) async {
    final base = state.draftsByNoteId[noteId];
    if (base == null) return;

    final next = base.copyWith(updatedAt: DateTime.now(), clearPasscode: true);

    await _draftBox.put(noteId, jsonEncode(next.toJson()));

    state = state.copyWith(
      draftsByNoteId: {...state.draftsByNoteId, noteId: next},
      currentDraft: next,
    );
  }

  Future<void> confirmSend(String noteId) async {
    await ensureDraft(noteId);
    final d = getDraft(noteId);
    if (d == null) throw Exception('Draft not found');

    final toType = (d.toType ?? 'EMAIL').toUpperCase();
    if (toType == 'USER') {
      final uid = (d.userId ?? '').trim();
      if (uid.isEmpty) throw Exception('Recipient user not set');
    } else if (toType == 'EMAIL') {
      final email = (d.email ?? '').trim();
      if (email.isEmpty) throw Exception('Recipient email not set');
    } else {
      throw Exception('Invalid recipient type: $toType');
    }

    final sendMode = (d.sendMode ?? 'SPECIFIC_TIME').toUpperCase();
    if (sendMode != 'SPECIFIC_TIME' &&
        sendMode != 'INSTANTLY' &&
        sendMode != 'PRIMARY_COUNTDOWN') {
      throw Exception('Invalid send mode: $sendMode');
    }

    if (sendMode == 'SPECIFIC_TIME') {
      final iso = (d.sendAtIso ?? '').trim();
      if (iso.isEmpty) throw Exception('Send time not set');
    }

    final passMode = (d.passcodeMode ?? 'NONE').toUpperCase();
    if (passMode != 'NONE' && passMode != 'PASSCODE' && passMode != 'QA') {
      throw Exception('Invalid passcode mode: $passMode');
    }

    if (passMode == 'PASSCODE') {
      final p = (d.passcode ?? '').trim();
      if (p.isEmpty) throw Exception('Passcode not set');
    } else if (passMode == 'QA') {
      final raw = (d.passcode ?? '').trim();
      if (raw.isEmpty) throw Exception('Q&A not set');
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final q = (map['q'] as String?)?.trim() ?? '';
        final a = (map['a'] as String?)?.trim() ?? '';
        if (q.isEmpty || a.isEmpty) throw Exception('Q&A not set');
      } catch (_) {
        throw Exception('Invalid Q&A payload');
      }
    }

    final builder = LoveSendTaskBuilder();
    final r = builder.build(d);

    if (r.scheduleType.name == 'primaryCountdown' &&
        (r.triggerRef?.isNotEmpty != true)) {
      throw Exception('Primary countdown not configured');
    }

    await ref
        .read(sendTaskProvider.notifier)
        .enqueue(
          idemKey: r.idemKey,
          type: r.type,
          scheduleType: r.scheduleType,
          scheduleAtIso: r.scheduleAtIso,
          triggerRef: r.triggerRef,
          recipient: r.recipient,
          payloadRef: r.payloadRef,
          cryptoMode: r.cryptoMode,
          cryptoHint: r.cryptoHint,
        );
  }
}
