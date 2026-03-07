// lib/features/notes_base/application/note_background_sync_runner.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/providers/app_providers.dart';
import 'package:lifecapsule8_app/core/constants/prefs_keys.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';

/// 后台同步运行器：与用户操作完全解耦
/// - 事件驱动：Hive box 变化时触发（更省电）
/// - 保底轮询：每 2 秒扫描一次（符合你的要求）
/// - 并发保护：避免重复同步
///
/// 接入方式：在 AppRoot/HomeShell/登录后某个常驻组件里加：
///   ref.watch(noteBackgroundSyncRunnerProvider);
final noteBackgroundSyncRunnerProvider =
    NotifierProvider<NoteBackgroundSyncRunner, void>(
      NoteBackgroundSyncRunner.new,
    );

class NoteBackgroundSyncRunner extends Notifier<void> {
  Timer? _timer;
  StreamSubscription? _sub;

  bool _syncing = false;

  // 你要求的扫描间隔
  static const Duration _pollInterval = Duration(seconds: 2);

  // 事件触发的 debounce（避免一连串 box.put 导致疯狂 sync）
  static const Duration _eventDebounce = Duration(milliseconds: 400);
  Timer? _debounceTimer;

  @override
  void build() {
    // 1) 事件驱动：box 变化就触发一次（debounce）
    _sub = ref.read(notesBoxProvider).watch().listen((_) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_eventDebounce, () {
        unawaited(_tick());
      });
    });

    // 2) 保底轮询：每 2 秒扫一次
    _timer = Timer.periodic(_pollInterval, (_) {
      unawaited(_tick());
    });

    // 3) 启动后先跑一次（把历史未同步补上）
    unawaited(_tick());

    // 4) 生命周期结束清理
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _debounceTimer = null;

      _timer?.cancel();
      _timer = null;

      _sub?.cancel();
      _sub = null;
    });
  }

  Future<void> _tick() async {
    final prefs = ref.read(sharedPrefsProvider);
    final state = prefs.getInt(PrefsKeys.syncState) ?? 0;
    if (state < 2) return;

    if (_syncing) return;
    _syncing = true;

    try {
      // 一次同步逻辑交给 NoteSyncService（保持职责单一）
      await ref.read(notesSyncServiceProvider).sync();
    } catch (e, st) {
      print('[NotesSyncRunner] tick failed: $e');
      print(st);
    } finally {
      _syncing = false;
    }
  }
}
