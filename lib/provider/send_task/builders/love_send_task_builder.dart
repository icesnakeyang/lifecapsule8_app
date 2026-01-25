import 'dart:convert';

import 'package:lifecapsule8_app/provider/love_letter/love_letter_draft.dart';
import '../send_task_model.dart';
import 'send_task_builder.dart';

class LoveSendTaskBuilder implements SendTaskBuilder<LoveLetterDraft> {
  const LoveSendTaskBuilder();

  static String _buildIdemKey({
    required SendTaskType type,
    required String payloadRef,
    required SendScheduleType scheduleType,
    required RecipientPayload recipient,
    String? scheduleAtIso,
    String? triggerRef,
  }) {
    // scheduleAtIso 对 atTime 很关键，必须进 idemKey
    // triggerRef 对 countdown 也必须进 idemKey
    return [
      type.name,
      payloadRef,
      scheduleType.name,
      recipient.self ? "1" : "0",
      scheduleAtIso ?? '',
      triggerRef ?? '',
    ].join('|');
  }

  @override
  SendTaskBuildResult build(LoveLetterDraft draft) {
    // 1) schedule
    final sendMode = (draft.sendMode ?? 'SPECIFIC_TIME').toUpperCase();

    final scheduleType = sendMode == 'INSTANTLY'
        ? SendScheduleType.instantly
        : SendScheduleType.atTime;

    final scheduleAtIso = scheduleType == SendScheduleType.atTime
        ? draft.sendAtIso
        : null;

    // 2) recipient
    final toType = (draft.toType ?? 'EMAIL').toUpperCase();
    final recipient = RecipientPayload(
      userCode: (draft.userCode ?? '').trim().isEmpty
          ? null
          : draft.userCode!.trim(),
      email: (draft.email ?? '').trim().isEmpty ? null : draft.email!.trim(),
      self: toType == 'SELF',
    );

    // 3) crypto
    final passMode = (draft.passcodeMode ?? 'NONE').toUpperCase();
    final cryptoMode = switch (passMode) {
      'PASSCODE' => CryptoMode.passcode,
      'QA' => CryptoMode.qa,
      _ => CryptoMode.none,
    };

    String? cryptoHint;
    if (cryptoMode == CryptoMode.qa) {
      // 只取 question，不取 answer（preview 安全展示）
      final raw = (draft.passcode ?? '').trim();
      if (raw.isNotEmpty) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final q = (map['q'] as String?)?.trim();
          if (q != null && q.isNotEmpty) cryptoHint = q;
        } catch (_) {}
      }
    }

    final idemKey = _buildIdemKey(
      type: SendTaskType.love,
      payloadRef: draft.noteId,
      scheduleType: scheduleType,
      recipient: recipient,
      scheduleAtIso: scheduleAtIso,
    );

    return SendTaskBuildResult(
      idemKey: idemKey,
      type: SendTaskType.love,
      scheduleType: scheduleType,
      scheduleAtIso: scheduleAtIso,
      recipient: recipient,
      payloadRef: draft.noteId,
      cryptoMode: cryptoMode,
      cryptoHint: cryptoHint,
    );
  }
}
