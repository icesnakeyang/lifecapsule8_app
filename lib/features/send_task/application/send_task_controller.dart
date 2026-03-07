// lib/features/send_task/application/send_task_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/send_task/domain/recipient_payload.dart';
import 'package:lifecapsule8_app/features/send_task/domain/send_task.dart';
import 'package:lifecapsule8_app/features/send_task/domain/send_task_enums.dart';

import 'send_task_providers.dart';

final sendTaskProvider = NotifierProvider<SendTaskController, void>(
  SendTaskController.new,
);

class SendTaskController extends Notifier<void> {
  @override
  void build() {}

  Future<void> enqueue({
    required String userId,
    required SendTaskType type,
    required SendScheduleType scheduleType,
    required String? scheduleAtIso,
    required RecipientPayload recipient,
    required String payloadRef,
    required CryptoMode cryptoMode,
    required String idemKey,
  }) async {
    final repo = ref.read(sendTaskRepositoryProvider);

    final now = DateTime.now();

    final task = SendTask(
      id: idemKey, // ✅ 用 idemKey 做唯一 id，天然去重（repo 若 upsert 会更稳）
      userId: userId,
      type: type,
      scheduleType: scheduleType,
      scheduleAtIso: scheduleAtIso,
      recipient: recipient,
      payloadRef: payloadRef,
      cryptoMode: cryptoMode,
      idemKey: idemKey,
      status: SendTaskStatus.pending,
      retryCount: 0,
      lastError: null,
      nextRetryAt: null,
      createdAt: now,
      updatedAt: now,
    );

    // ✅ 你 repo 接口如果是 add/upsert/save，按你实际方法名改这里
    await repo.enqueue(task);
  }
}
