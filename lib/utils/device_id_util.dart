import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdUtil {
  static const _key = "lifecapsule_device_id";
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final newId = const Uuid().v4();
    await prefs.setString(_key, newId);
    return newId;
  }
}
