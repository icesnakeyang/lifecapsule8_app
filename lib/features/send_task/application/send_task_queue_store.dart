// lib/features/send_task/application/send_task_queue_store.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/send_task.dart';
import 'send_task_providers.dart';

final sendTaskQueueStoreProvider =
    AsyncNotifierProvider<SendTaskQueueStore, List<SendTask>>(
      SendTaskQueueStore.new,
    );

class SendTaskQueueStore extends AsyncNotifier<List<SendTask>> {
  @override
  Future<List<SendTask>> build() async {
    final asyncList = ref.watch(sendTaskListStreamProvider);
    // StreamProvider 会自动随 box 变化而推送，这里把它转换成 state
    return asyncList.value ?? const <SendTask>[];
  }

  // 可选：如果你还想手动 reload（一般不需要）
  Future<void> reload() async {
    ref.invalidate(sendTaskListStreamProvider);
  }
}
