import 'package:lifecapsule8_app/app/router/app_route.dart';
import 'package:lifecapsule8_app/features/profile/presentation/my_profile.dart';
import 'package:lifecapsule8_app/features/profile/profile_route_paths.dart';

final List<AppRoute> profileRoutes = [
  AppRoute(name: ProfileRoutePaths.profile, builder: (_) => const MyProfile()),
];
