// lib/features/send_task/application/send_task_processor.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/send_task_repository.dart';
import '../domain/send_task_enums.dart';
import 'send_task_providers.dart';

final sendTaskProcessorProvider = Provider<SendTaskProcessor>((ref) {
  return SendTaskProcessor(ref);
});

class SendTaskProcessor {
  final Ref ref;
  SendTaskRepository get _repo => ref.read(sendTaskRepositoryProvider);

  SendTaskProcessor(this.ref);

  Future<void> processPendingOnce() async {
    final tasks = await _repo.list(includeDone: false);
    final now = DateTime.now();

    for (final t in tasks) {
      if (t.status != SendTaskStatus.pending &&
          t.status != SendTaskStatus.failed) {
        continue;
      }
      if (t.nextRetryAt != null && t.nextRetryAt!.isAfter(now)) continue;

      // 1) 标记 sending
      await _repo.markStatus(id: t.id, status: SendTaskStatus.sending);

      try {
        // TODO: 调你的 API：sendFutureLetter / sendLoveLetter / ...
        // await api.send(...)

        // 2) 成功
        await _repo.markStatus(id: t.id, status: SendTaskStatus.sent);
      } catch (e) {
        final retry = t.retryCount + 1;

        // 简单退避：1m, 5m, 30m, 2h...
        final backoff = Duration(
          minutes: retry == 1
              ? 1
              : retry == 2
              ? 5
              : retry == 3
              ? 30
              : 120,
        );

        await _repo.markStatus(
          id: t.id,
          status: SendTaskStatus.failed,
          retryCount: retry,
          lastError: e.toString(),
          nextRetryAt: DateTime.now().add(backoff),
        );
      }
    }
  }
}
