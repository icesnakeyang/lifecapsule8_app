import 'package:flutter/material.dart';
import 'package:lifecapsule8_app/app/app.dart';
import 'package:lifecapsule8_app/app/bootstrap.dart';
import 'package:lifecapsule8_app/app/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lifecapsule8_app/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  final boot = await AppBootstrap.init();

  print('AppCofnig.baseUrl=${AppConfig.baseUrl}');

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(boot.prefs),
        deviceIdProvider.overrideWithValue(boot.deviceId),
      ],
      child: const LifeCapsuleApp(),
    ),
  );
}
