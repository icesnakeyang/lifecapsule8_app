import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifecapsule8_app/hive/hive_boxes.dart';
import 'package:path_provider/path_provider.dart';

class HiveSetup {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    final dir = await _resolveHiveDir();
    Hive.init(dir.path);

    await Hive.openBox<String>(HiveBoxes.notes);
    await Hive.openBox(HiveBoxes.crypto);
    await Hive.openBox(HiveBoxes.loveLetterDrafts);
    await Hive.openBox<String>(HiveBoxes.sendTasks);
    await Hive.openBox<String>(HiveBoxes.lastWishes);
    await Hive.openBox<String>(HiveBoxes.inspirationBox);
    await Hive.openBox<String>(HiveBoxes.futureBox);
    await Hive.openBox<String>(HiveBoxes.outbox);
  }

  /// Hive 专用目录（桌面端避开 OneDrive）
  static Future<Directory> _resolveHiveDir() async {
    final base = await getApplicationSupportDirectory();
    final hiveDir = Directory('${base.path}/hive');

    if (!await hiveDir.exists()) {
      await hiveDir.create(recursive: true);
    }
    return hiveDir;
  }

  // 建议使用 deleteBoxFromDisk 防止旧文件残留
  static Future<void> clearHive() async {
    await Hive.deleteBoxFromDisk(HiveBoxes.notes);
    await Hive.deleteBoxFromDisk(HiveBoxes.crypto);
    await Hive.deleteBoxFromDisk(HiveBoxes.loveLetterDrafts);
    await Hive.deleteBoxFromDisk(HiveBoxes.sendTasks);
    await Hive.deleteBoxFromDisk(HiveBoxes.lastWishes);
    await Hive.deleteBoxFromDisk(HiveBoxes.inspirationBox);
    await Hive.deleteBoxFromDisk(HiveBoxes.futureBox);
    await Hive.deleteBoxFromDisk(HiveBoxes.outbox);
  }
}
