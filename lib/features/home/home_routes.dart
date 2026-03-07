import 'package:lifecapsule8_app/app/router/app_route.dart';
import 'package:lifecapsule8_app/features/home/home_route_paths.dart';
import 'package:lifecapsule8_app/features/home/presentation/home_page.dart';

final List<AppRoute> homeRoutes = [
  AppRoute(name: HomeRoutePaths.home, builder: (_) => const HomePage()),
];
