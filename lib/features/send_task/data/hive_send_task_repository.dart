// lib/features/send_task/data/hive_send_task_repository.dart
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:lifecapsule8_app/core/constants/hive_boxes.dart';

import '../domain/send_task.dart';
import '../domain/send_task_enums.dart';
import 'send_task_repository.dart';

class HiveSendTaskRepository implements SendTaskRepository {
  final Box<String> _box;

  HiveSendTaskRepository({Box<String>? box})
    : _box = box ?? Hive.box<String>(HiveBoxes.syncOutbox);

  SendTask _decode(String raw) =>
      SendTask.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());

  String _encode(SendTask t) => jsonEncode(t.toJson());

  bool _isDone(SendTaskStatus s) =>
      s == SendTaskStatus.sent || s == SendTaskStatus.canceled;

  @override
  Future<List<SendTask>> list({bool includeDone = false}) async {
    final out = <SendTask>[];
    for (final k in _box.keys) {
      final raw = _box.get(k);
      if (raw == null || raw.isEmpty) continue;
      try {
        final t = _decode(raw);
        if (!includeDone && _isDone(t.status)) continue;
        out.add(t);
      } catch (_) {}
    }
    out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return out;
  }

  @override
  Stream<List<SendTask>> watchList({bool includeDone = false}) async* {
    yield await list(includeDone: includeDone);
    yield* _box.watch().asyncMap((_) => list(includeDone: includeDone));
  }

  @override
  Future<SendTask?> findByIdemKey(String idemKey) async {
    for (final k in _box.keys) {
      final raw = _box.get(k);
      if (raw == null || raw.isEmpty) continue;
      try {
        final t = _decode(raw);
        if (t.idemKey != idemKey) continue;
        // 只对“未完成”的任务做幂等
        if (_isDone(t.status)) continue;
        return t;
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<SendTask> enqueue(SendTask task) async {
    final existed = await findByIdemKey(task.idemKey);
    if (existed != null) return existed;

    await _box.put(task.id, _encode(task));
    return task;
  }

  @override
  Future<void> markStatus({
    required String id,
    required SendTaskStatus status,
    String? lastError,
    DateTime? nextRetryAt,
    int? retryCount,
  }) async {
    final raw = _box.get(id);
    if (raw == null || raw.isEmpty) return;
    final cur = _decode(raw);
    final now = DateTime.now();

    final updated = cur.copyWith(
      status: status,
      lastError: lastError,
      nextRetryAt: nextRetryAt,
      retryCount: retryCount,
      updatedAt: now,
    );

    await _box.put(id, _encode(updated));
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
