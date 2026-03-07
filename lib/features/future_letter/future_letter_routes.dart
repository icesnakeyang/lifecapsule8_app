import 'package:flutter/material.dart';
import 'package:lifecapsule8_app/app/router/app_route.dart';
import 'package:lifecapsule8_app/features/future_letter/future_letter_route_paths.dart';
import 'package:lifecapsule8_app/features/future_letter/presentation/future_letter_done_page.dart';
import 'package:lifecapsule8_app/features/future_letter/presentation/future_letter_list_page.dart';
import 'package:lifecapsule8_app/features/future_letter/presentation/future_letter_preview_page.dart';
import 'package:lifecapsule8_app/features/future_letter/presentation/future_letter_recipient_page.dart';
import 'package:lifecapsule8_app/features/future_letter/presentation/future_letter_schedule_page.dart';
import 'package:lifecapsule8_app/features/future_letter/presentation/future_letter_write_page.dart';

final List<AppRoute> futureLetterRoutes = [
  AppRoute(
    name: FutureLetterRoutePaths.write,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final noteId = args?['noteId'] as String?;
      return FutureLetterWritePage(noteId: noteId);
    },
  ),
  AppRoute(
    name: FutureLetterRoutePaths.list,
    builder: (_) => const FutureLetterListPage(),
  ),
  AppRoute(
    name: FutureLetterRoutePaths.schedule,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final noteId = args?['noteId'] as String;
      return FutureLetterSchedulePage(noteId: noteId);
    },
  ),
  AppRoute(
    name: FutureLetterRoutePaths.recipient,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final noteId = args?['noteId'] as String;
      return FutureLetterRecipientPage(noteId: noteId);
    },
  ),
  AppRoute(
    name: FutureLetterRoutePaths.preview,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final noteId = args?['noteId'] as String;
      return FutureLetterPreviewPage(noteId: noteId);
    },
  ),
  AppRoute(
    name: FutureLetterRoutePaths.done,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final noteId = args?['noteId'] as String?;
      final success = args?['success'] as bool?;
      final message = args?['message'] as String?;
      return FutureLetterDonePage(
        noteId: noteId,
        success: success,
        message: message,
      );
    },
  ),
];
