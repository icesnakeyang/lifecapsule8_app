import 'package:lifecapsule8_app/app/router/app_route.dart';
import 'package:lifecapsule8_app/features/welcome/presentation/welcome_page.dart';
import 'package:lifecapsule8_app/features/welcome/welcome_route_paths.dart';

final List<AppRoute> welcomeRoutes = [
  AppRoute(
    name: WelcomeRoutePaths.welcome,
    builder: (_) => const WelcomePage(),
  ),
];
