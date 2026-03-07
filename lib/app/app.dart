import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lifecapsule8_app/app/i18n/locale_provider.dart';
import 'package:lifecapsule8_app/app/router/app_generate_route.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_background_sync_runner.dart';
import 'package:lifecapsule8_app/features/welcome/welcome_route_paths.dart';

class LifeCapsuleApp extends ConsumerWidget {
  const LifeCapsuleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //启动后台同步 Runner（App 常驻）
    ref.watch(noteBackgroundSyncRunnerProvider);
    final theme = ref.watch(themeDataProvider);
    final locale = ref.watch(localeProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: locale,
          onGenerateRoute: appGenerateRoute,
          initialRoute: WelcomeRoutePaths.welcome,
        );
      },
    );
  }
}
