// lib/features/send_task/data/send_task_repository.dart
import '../domain/send_task.dart';
import '../domain/send_task_enums.dart';

abstract class SendTaskRepository {
  Future<List<SendTask>> list({bool includeDone = false});
  Stream<List<SendTask>> watchList({bool includeDone = false});

  /// idemKey 幂等：如果已有同 idemKey 的 pending/sending，直接返回已有任务
  Future<SendTask> enqueue(SendTask task);

  Future<void> markStatus({
    required String id,
    required SendTaskStatus status,
    String? lastError,
    DateTime? nextRetryAt,
    int? retryCount,
  });

  Future<void> delete(String id);

  Future<SendTask?> findByIdemKey(String idemKey);
}
