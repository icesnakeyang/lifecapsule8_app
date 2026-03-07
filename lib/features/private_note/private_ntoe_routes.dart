import 'package:flutter/material.dart';
import 'package:lifecapsule8_app/app/router/app_route.dart';
import 'package:lifecapsule8_app/features/private_note/private_note_route_paths.dart';
import 'package:lifecapsule8_app/features/private_note/presentation/private_note_edit_page.dart';
import 'package:lifecapsule8_app/features/private_note/presentation/private_note_list_page.dart';

final List<AppRoute> privateNoteRoutes = [
  AppRoute(
    name: PrivateNoteRoutePaths.list,
    builder: (_) => const PrivateNoteListPage(),
  ),
  AppRoute(
    name: PrivateNoteRoutePaths.edit,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      String? noteId;
      if (args is Map) {
        noteId = args['noteId'] as String?;
      }
      return PrivateNoteEditPage(noteId: noteId);
    },
  ),
];
