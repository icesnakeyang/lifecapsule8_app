import 'package:lifecapsule8_app/app/router/app_route.dart';
import 'package:lifecapsule8_app/features/inspiration/inspiration_route_paths.dart';
import 'package:lifecapsule8_app/features/inspiration/presentation/inpiration_page.dart';

final List<AppRoute> inspirationRoutes = [
  AppRoute(
    name: InspirationRoutePaths.page,
    builder: (_) => const InspirationPage(),
  ),
];
