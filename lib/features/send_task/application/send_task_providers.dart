// lib/features/send_task/application/send_task_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/send_task/domain/send_task.dart';

import '../data/hive_send_task_repository.dart';
import '../data/send_task_repository.dart';

final sendTaskRepositoryProvider = Provider<SendTaskRepository>((ref) {
  return HiveSendTaskRepository();
});

final sendTaskListStreamProvider = StreamProvider.autoDispose<List<SendTask>>((
  ref,
) {
  final repo = ref.watch(sendTaskRepositoryProvider);
  return repo.watchList(includeDone: false);
});
