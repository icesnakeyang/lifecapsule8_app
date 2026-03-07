import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPrefsProvider must be overridden in main()');
});

final deviceIdProvider = Provider<String>((ref) {
  throw UnimplementedError('deviceIdProvider must be overridden in main()');
});
