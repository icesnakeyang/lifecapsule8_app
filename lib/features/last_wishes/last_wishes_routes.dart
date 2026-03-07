import 'package:lifecapsule8_app/app/router/app_route.dart';
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_route_paths.dart';
import 'package:lifecapsule8_app/features/last_wishes/presentation/last_wishes_edit_page.dart';
import 'package:lifecapsule8_app/features/last_wishes/presentation/last_wishes_intro_page.dart';
import 'package:lifecapsule8_app/features/last_wishes/presentation/last_wishes_list_page.dart';

import 'package:lifecapsule8_app/features/last_wishes/presentation/last_wishes_recipient_page.dart';
import 'package:lifecapsule8_app/features/last_wishes/presentation/last_wishes_send_time_page.dart';
import 'package:lifecapsule8_app/features/last_wishes/presentation/last_wishes_preview_page.dart';
import 'package:lifecapsule8_app/features/last_wishes/presentation/last_wishes_done_page.dart';

final List<AppRoute> lastWishesRoutes = [
  AppRoute(
    name: LastWishesRoutePaths.edit,
    builder: (_) => const LastWishesEditPage(),
  ),
  AppRoute(
    name: LastWishesRoutePaths.recipient,
    builder: (_) => const LastWishesRecipientPage(),
  ),
  AppRoute(
    name: LastWishesRoutePaths.sendTime,
    builder: (_) => const LastWishesSendTimePage(),
  ),
  AppRoute(
    name: LastWishesRoutePaths.preview,
    builder: (_) => const LastWishesPreviewPage(),
  ),
  AppRoute(
    name: LastWishesRoutePaths.done,
    builder: (_) => const LastWishesDonePage(),
  ),
  AppRoute(
    name: LastWishesRoutePaths.intro,
    builder: (_) => const LastWishesIntroPage(),
  ),
  AppRoute(
    name: LastWishesRoutePaths.list,
    builder: (_) => const LastWishesListPage(),
  ),
];
