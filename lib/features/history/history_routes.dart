import 'package:flutter/cupertino.dart';
import 'package:lifecapsule8_app/app/router/app_route.dart';
import 'package:lifecapsule8_app/features/history/history_route_paths.dart';
import 'package:lifecapsule8_app/features/history/presentation/history_detail_page.dart';
import 'package:lifecapsule8_app/features/history/presentation/history_list_page.dart';

final List<AppRoute> historyRoutes = [
  AppRoute(
    name: HistoryRoutePaths.history,
    builder: (_) => const HistoryListPage(),
  ),
  AppRoute(
    name: HistoryRoutePaths.historyDetail,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      final noteId = args ?? '';
      return HistoryDetailPage(noteId: noteId);
    },
  ),
];
