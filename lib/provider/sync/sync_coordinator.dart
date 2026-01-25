import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/note/note_provider.dart';
import 'package:lifecapsule8_app/provider/send_task/send_task_notifier.dart';

final syncCoordinatorProvider = NotifierProvider<SyncCoordinator, void>(
  SyncCoordinator.new,
);

class SyncCoordinator extends Notifier<void> {
  Timer? _timer;
  bool _running = false;

  @override
  void build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    // 每 5 秒扫一次（你可以调）
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      _tick();
    });
  }

  Future<void> _tick() async {
    if (_running) return;
    _running = true;
    try {
      // ✅ 这里不要让任何一个 sync 抛出异常导致定时器停
      // 1) 同步 notes_box -> cloud note_base/content
      await ref.read(noteProvider.notifier).syncToCloud();

      // 2) 同步 send_task_box -> cloud send_task
      await ref.read(sendTaskProvider.notifier).syncToCloud();

      // 3) 可选：future_box -> cloud note_base/content（若 future 不写 notes_box）
      // await ref.read(futureLetterProvider.notifier).syncToCloud();
    } catch (_) {
      // swallow
    } finally {
      _running = false;
    }
  }
}
