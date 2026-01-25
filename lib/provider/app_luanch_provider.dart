import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appLaunchProvider = NotifierProvider<AppLaunchNotifier, int>(
  () => AppLaunchNotifier(),
);

class AppLaunchNotifier extends Notifier<int> {
  static const _key = "launch_count";

  @override
  int build() {
    _load();
    return 0; // 初始值，稍后会被 load 覆盖
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_key) ?? 0;

    // 每次启动都 +1
    final newCount = count + 1;
    state = newCount;

    await prefs.setInt(_key, newCount);
  }

  /// 用于其他页面判断是否首次启动
  bool get isFirstLaunch => state <= 1;
}
