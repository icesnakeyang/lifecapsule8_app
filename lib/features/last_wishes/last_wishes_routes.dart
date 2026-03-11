import 'package:flutter/material.dart';
import 'package:lifecapsule8_app/app/router/app_route.dart';
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_route_paths.dart';
import 'package:lifecapsule8_app/features/last_wishes/presentation/last_wishes_done_page.dart';
import 'package:lifecapsule8_app/features/last_wishes/presentation/last_wishes_edit_page.dart';
import 'package:lifecapsule8_app/features/last_wishes/presentation/last_wishes_intro_page.dart';
import 'package:lifecapsule8_app/features/last_wishes/presentation/last_wishes_list_page.dart';
import 'package:lifecapsule8_app/features/last_wishes/presentation/last_wishes_preview_page.dart';
import 'package:lifecapsule8_app/features/last_wishes/presentation/last_wishes_recipient_page.dart';

final List<AppRoute> lastWishesRoutes = [
  AppRoute(
    name: LastWishesRoutePaths.edit,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final noteId = _readNoteId(args) ?? 'last_wishes';
      return LastWishesEditPage(noteId: noteId);
    },
  ),

  AppRoute(
    name: LastWishesRoutePaths.recipient,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final noteId = _readNoteId(args);
      return LastWishesRecipientPage(noteId: noteId);
    },
  ),

  AppRoute(
    name: LastWishesRoutePaths.preview,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final noteId = _readNoteId(args);
      return LastWishesPreviewPage(noteId: noteId);
    },
  ),

  AppRoute(
    name: LastWishesRoutePaths.done,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final noteId = _readNoteId(args);
      return LastWishesDonePage(noteId: noteId);
    },
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

String? _readNoteId(Object? args) {
  if (args is Map) {
    final v = args['noteId'];
    if (v is String && v.trim().isNotEmpty) {
      return v.trim();
    }
  }
  return null;
}
