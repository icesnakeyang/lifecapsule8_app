import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifecapsule8_app/core/constants/hive_boxes.dart';

class HiveInit {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<String>(HiveBoxes.notes),
      Hive.openBox(HiveBoxes.crypto),
      Hive.openBox(HiveBoxes.settings),
      // Hive.openBox(HiveBoxes.syncOutbox),
      Hive.openBox(HiveBoxes.indexes),
    ]);
  }
}
