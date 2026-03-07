import 'package:flutter/material.dart';
import 'package:lifecapsule8_app/core/utils/device_id.dart';
import 'package:lifecapsule8_app/data/local/hive/hive_init.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BootstrapResult {
  final SharedPreferences prefs;
  final String deviceId;
  const BootstrapResult({required this.prefs, required this.deviceId});
}

class AppBootstrap {
  static const String kSyncStage = 'sync_stage'; // 0/1/2
  static const String kBackupNudgeDismissed = 'backup_nudge_dismissed';

  static Future<BootstrapResult> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    await HiveInit.init();
    final prefs = await SharedPreferences.getInstance();
    // ✅ init defaults (only if missing)
    if (!prefs.containsKey(kSyncStage)) {
      await prefs.setInt(kSyncStage, 0);
    }
    if (!prefs.containsKey(kBackupNudgeDismissed)) {
      await prefs.setBool(kBackupNudgeDismissed, false);
    }
    final deviceId = await DeviceId.getOrCreate(prefs);

    return BootstrapResult(prefs: prefs, deviceId: deviceId);
  }
}
