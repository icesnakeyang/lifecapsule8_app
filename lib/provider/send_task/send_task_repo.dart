import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:lifecapsule8_app/hive/hive_boxes.dart';
import 'send_task_model.dart';

class SendTaskRepo {
  SendTaskRepo();

  Box<String> get _box => Hive.box<String>(HiveBoxes.sendTasks);

  Future<void> upsert(SendTask task) async {
    await _box.put(task.taskId, task.encode());
  }

  Future<void> remove(String taskId) async {
    await _box.delete(taskId);
  }

  SendTask? getById(String taskId) {
    final raw = _box.get(taskId);
    if (raw == null || raw.isEmpty) return null;
    return SendTask.decode(raw);
  }

  List<SendTask> listAll() {
    final list = <SendTask>[];

    for (final raw in _box.values) {
      final s = raw.trim();
      if (s.trim().isEmpty || s == 'null') continue;
      try {
        final decoded = jsonDecode(s);
        if (decoded is! Map<String, dynamic>) continue;
        list.add(SendTask.fromJson(decoded));
      } catch (_) {}
    }
    return list;
  }

  List<SendTask> listByStatus(Set<SendTaskStatus> statuses) {
    final all = listAll();
    return all.where((t) => statuses.contains(t.status)).toList();
  }

  SendTask? findByIdemKey(String idemKey) {
    for (final raw in _box.values) {
      if (raw.trim().isEmpty) continue;
      try {
        final t = SendTask.decode(raw);
        if (t.idemKey == idemKey) return t;
      } catch (_) {}
    }
    return null;
  }
}
