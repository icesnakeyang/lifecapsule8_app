import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncStage {
  static const key = 'sync_state';
  static const int none = 0;
  static const int hasKey = 1;
  static const int boundEmail = 2;
}

final syncStageProvider = NotifierProvider<SyncStageNotifier, int>(
  SyncStageNotifier.new,
);

class SyncStageNotifier extends Notifier<int> {
  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  int build() {
    return _prefs.getInt(SyncStage.key) ?? SyncStage.none;
  }

  Future<void> _set(int next) async {
    final cur = state;
    if (next <= cur) return; // 只允许升级
    state = next;
    await _prefs.setInt(SyncStage.key, next);
  }

  Future<void> markHasMasterKey() => _set(SyncStage.hasKey);
  Future<void> markBoundEmail() => _set(SyncStage.boundEmail);

  /// 可选：重置（只在 Reset all data 时调用）
  Future<void> reset() async {
    state = SyncStage.none;
    await _prefs.setInt(SyncStage.key, SyncStage.none);
  }
}
