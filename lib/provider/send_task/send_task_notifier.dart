import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/api/api.dart';
import 'package:lifecapsule8_app/utils/dt_localized.dart';
import 'package:uuid/uuid.dart';

import 'send_task_model.dart';
import 'send_task_repo.dart';
import 'send_task_state.dart';

final sendTaskProvider = NotifierProvider<SendTaskNotifier, SendTaskState>(
  SendTaskNotifier.new,
);

class SendTaskNotifier extends Notifier<SendTaskState> {
  late final SendTaskRepo _repo;

  Timer? _refreshDebounce;

  bool _syncing = false;

  @override
  SendTaskState build() {
    _repo = SendTaskRepo();
    final tasks = _repo.listAll();
    tasks.sort((a, b) => b.createdAtIso.compareTo(a.createdAtIso));
    return SendTaskState(tasks: tasks);
  }

  Future<void> syncToCloud() async {
    if (_syncing) return;
    _syncing = true;
    try {
      // 只同步 pending / failed（你也可以加 sending 兜底）
      final list = _repo.listByStatus({
        SendTaskStatus.pending,
        SendTaskStatus.failed,
      });

      for (final t in list) {
        // 标记 sending（避免重复并发）
        await _repo.upsert(
          t.copyWith(
            status: SendTaskStatus.sending,
            updatedAtIso: toIso8601WithOffset(DateTime.now()),
          ),
        );

        try {
          // ✅ 只上云“元数据”，绝不上传 passcode/answer
          final meta = <String, dynamic>{
            'idemKey': t.idemKey,
            'clientTaskId': t.taskId,
            'type': t.type.name,
            'scheduleType': t.scheduleType.name,
            'scheduleAtIso': t.scheduleAtIso,
            'triggerRef': t.triggerRef,
            'recipient': t.recipient.toJson(),
            'payloadRef': t.payloadRef,
            'cryptoMode': t.cryptoMode.name,
            'cryptoHint': t.cryptoHint,
            'clientCreatedAtIso': t.createdAtIso,
            'clientUpdatedAtIso': t.updatedAtIso,
          };

          // 你需要在 Api 里加这个接口
          final res = await Api.apiUpsertSendTask(meta);

          final code = int.tryParse(res['code']?.toString() ?? '') ?? -1;
          if (code != 0) throw Exception(res['msg'] ?? 'upsert failed');

          // 上云成功：标记 scheduled（表示服务器已接管调度）
          final updated = _repo.getById(t.taskId);
          final nowIso = toIso8601WithOffset(DateTime.now());
          if (updated != null) {
            await _repo.upsert(
              updated.copyWith(
                status: SendTaskStatus.scheduled,
                lastError: null,
                updatedAtIso: nowIso,
              ),
            );
          }
        } catch (e) {
          final latest = _repo.getById(t.taskId) ?? t;
          await _repo.upsert(
            latest.copyWith(
              status: SendTaskStatus.failed,
              retryCount: latest.retryCount + 1,
              lastError: e.toString(),
              updatedAtIso: toIso8601WithOffset(DateTime.now()),
            ),
          );
        }
      }

      // 刷新 state（按你当前 state 结构调整）
      state = state.copyWith(tasks: _repo.listAll());
    } finally {
      _syncing = false;
    }
  }

  void _reload() {
    final tasks = _repo.listAll();
    tasks.sort((a, b) => b.createdAtIso.compareTo(a.createdAtIso));
    state = state.copyWith(tasks: tasks);
  }

  void refresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 80), _reload);
  }

  Future<void> upsert(SendTask task) async {
    await _repo.upsert(task);
    _reload();
  }

  Future<void> remove(String taskId) async {
    await _repo.remove(taskId);
    _reload();
  }

  /// ✅ 统一入口：创建一个“待发送任务”（MVP：先入队，后续 runner 再同步服务器）
  Future<SendTask> enqueue({
    required SendTaskType type,
    required SendScheduleType scheduleType,
    String? scheduleAtIso,
    String? triggerRef,
    required RecipientPayload recipient,
    String? recipientRef,
    required String payloadRef,
    required CryptoMode cryptoMode,
    String? cryptoHint,
    required String idemKey,
  }) async {
    final existed = _repo.findByIdemKey(idemKey);
    if (existed != null) return existed;

    final nowIso = toIso8601WithOffset(DateTime.now());
    final task = SendTask(
      taskId: const Uuid().v4(),
      idemKey: idemKey,
      type: type,
      status: SendTaskStatus.pending,
      scheduleType: scheduleType,
      scheduleAtIso: scheduleAtIso,
      triggerRef: triggerRef,
      recipient: recipient,
      payloadRef: payloadRef,
      cryptoMode: cryptoMode,
      cryptoHint: cryptoHint,
      createdAtIso: nowIso,
      updatedAtIso: nowIso,
    );
    await upsert(task);
    return task;
  }

  Future<void> markStatus(
    String taskId,
    SendTaskStatus status, {
    String? lastError,
    int? retryCount,
  }) async {
    final t = _repo.getById(taskId);
    if (t == null) return;

    final updated = t.copyWith(
      status: status,
      lastError: lastError,
      retryCount: retryCount,
      updatedAtIso: toIso8601WithOffset(DateTime.now()),
    );
    await upsert(updated);
  }

  Future<void> upsertLastWishesTask({
    required String noteId,
    required String recipientEmail,
    required DateTime scheduleAt,
  }) async {
    final idemKey = 'last_wishes:$noteId';

    final existed = _repo.findByIdemKey(idemKey);
    final nowIso = toIso8601WithOffset(DateTime.now());
    final scheduleAtIso = toIso8601WithOffset(scheduleAt); // ✅ 强制带 offset
    final recipient = RecipientPayload(email: recipientEmail);

    if (existed == null) {
      await _repo.upsert(
        SendTask(
          taskId: const Uuid().v4(),
          idemKey: idemKey,
          type: SendTaskType.lastWishes,
          status: SendTaskStatus.pending,
          scheduleType: SendScheduleType.atTime,
          scheduleAtIso: scheduleAtIso,
          recipient: recipient,
          payloadRef: noteId,
          cryptoMode: CryptoMode.none,
          createdAtIso: nowIso,
          updatedAtIso: nowIso,
        ),
      );
    } else {
      await _repo.upsert(
        existed.copyWith(
          status: SendTaskStatus.pending, // ✅ 重置为待同步
          scheduleAtIso: scheduleAtIso,
          recipient: recipient,
          updatedAtIso: nowIso,
        ),
      );
    }

    final tasks = _repo.listAll()
      ..sort((a, b) => b.createdAtIso.compareTo(a.createdAtIso));
    state = state.copyWith(tasks: tasks);
  }
}
