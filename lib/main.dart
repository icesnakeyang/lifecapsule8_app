import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lifecapsule8_app/api/api_client.dart';
import 'package:lifecapsule8_app/global/global_device.dart';
import 'package:lifecapsule8_app/hive/hive_setup.dart';
import 'package:lifecapsule8_app/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/locale_provider.dart';
import 'package:lifecapsule8_app/theme/theme_provider.dart';
import 'package:lifecapsule8_app/utils/device_id_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //每次安装实例都会生成一个deviceId，用于用户重装app时同步数据
  GlobalDevice.deviceId = await DeviceIdUtil.getDeviceId();
  GlobalDevice.initialized = true;

  await HiveSetup.init();

  // await HiveSetup.clearHive();
  final prefs = await SharedPreferences.getInstance();
  // prefs.remove('launch_count');
  // prefs.remove('app_locale_code');
  // prefs.remove('local_user_info');
  // prefs.remove('flutter.app_theme_id');
  // prefs.remove('lifecapsule_device_id');
  // prefs.remove('private_note_entry_count');

  await ApiClient.init();
  runApp(const ProviderScope(child: LifeCapsuleApp()));
}

class LifeCapsuleApp extends ConsumerWidget {
  const LifeCapsuleApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final themeData = ref.watch(themeDataProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          locale: currentLocale,
          theme: themeData,
          onGenerateRoute: appGenerateRoute,
          initialRoute: '/welcome',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
            Locale('ms'),
            Locale('id'),
            Locale('th'),
            Locale('vi'),
            Locale('ja'),
            Locale('ko'),
            Locale('fr'),
            Locale('de'),
            Locale('es'),
          ],
        );
      },
    );
  }
}
