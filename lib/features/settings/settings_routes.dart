import 'package:lifecapsule8_app/app/router/app_route.dart';
import 'package:lifecapsule8_app/features/settings/presentation/settings_page.dart';
import 'package:lifecapsule8_app/features/settings/settings_route_paths.dart';

final List<AppRoute> settingsRoutes = [
  AppRoute(
    name: SettingsRoutePaths.settings,
    builder: (_) => const SettingsPage(),
  ),
];
