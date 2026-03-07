import 'package:lifecapsule8_app/app/router/app_route.dart';
import 'package:lifecapsule8_app/features/crypto/crypto_routes.dart';
import 'package:lifecapsule8_app/features/future_letter/future_letter_routes.dart';
import 'package:lifecapsule8_app/features/history/history_routes.dart';
import 'package:lifecapsule8_app/features/home/home_routes.dart';
import 'package:lifecapsule8_app/features/inspiration/inspiration_routes.dart';
import 'package:lifecapsule8_app/features/love_letter/love_routes.dart';
import 'package:lifecapsule8_app/features/private_note/private_ntoe_routes.dart';
import 'package:lifecapsule8_app/features/profile/profile_routes.dart';
import 'package:lifecapsule8_app/features/settings/settings_routes.dart';
import 'package:lifecapsule8_app/features/welcome/welcome_routes.dart';
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_routes.dart';

final List<AppRoute> appRoutes = [
  ...welcomeRoutes,
  ...privateNoteRoutes,
  ...homeRoutes,
  ...futureLetterRoutes,
  ...loveLetterRoutes,
  ...inspirationRoutes,
  ...historyRoutes,
  ...lastWishesRoutes,
  ...profileRoutes,
  ...cryptoRoutes,
  ...settingsRoutes,
];
