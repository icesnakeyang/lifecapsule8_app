import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class DeviceId {
  static const _k = 'device_id';

  static Future<String> getOrCreate(SharedPreferences prefs) async {
    final existing = prefs.getString(_k);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = _gen();
    await prefs.setString(_k, id);
    return id;
  }

  static String _gen() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    final sb = StringBuffer('lc_');
    for (var i = 0; i < 24; i++) {
      sb.write(chars[rnd.nextInt(chars.length)]);
    }
    return sb.toString();
  }
}
