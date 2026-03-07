import 'package:flutter/material.dart';
import 'package:lifecapsule8_app/app/router/app_route.dart';
import 'package:lifecapsule8_app/features/love_letter/love_route_paths.dart';
import 'package:lifecapsule8_app/features/love_letter/presentation/love_letter_action_page.dart';
import 'package:lifecapsule8_app/features/love_letter/presentation/love_letter_list_page.dart';
import 'package:lifecapsule8_app/features/love_letter/presentation/love_letter_edit_page.dart';
import 'package:lifecapsule8_app/features/love_letter/presentation/love_letter_recipient_page.dart';
import 'package:lifecapsule8_app/features/love_letter/presentation/love_letter_send_time_page.dart';
import 'package:lifecapsule8_app/features/love_letter/presentation/love_letter_passcode_page.dart';
import 'package:lifecapsule8_app/features/love_letter/presentation/love_letter_preview_page.dart';

final List<AppRoute> loveLetterRoutes = [
  AppRoute(
    name: LoveRoutePaths.list,
    builder: (_) => const LoveLetterListPage(),
  ),

  AppRoute(
    name: LoveRoutePaths.edit,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final noteId = args?['noteId'] as String?;
      return LoveLetterEditPage(noteId: noteId);
    },
  ),

  AppRoute(
    name: LoveRoutePaths.recipient,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final noteId = args?['noteId'] as String?;
      return LoveLetterRecipientPage(noteId: noteId);
    },
  ),

  AppRoute(
    name: LoveRoutePaths.sendTime,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final noteId = args?['noteId'] as String?;
      return LoveLetterSendTimePage(noteId: noteId);
    },
  ),

  AppRoute(
    name: LoveRoutePaths.passcode,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final noteId = args?['noteId'] as String;
      return LoveLetterPasscodePage(noteId: noteId);
    },
  ),

  AppRoute(
    name: LoveRoutePaths.preview,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final noteId = args?['noteId'] as String?;
      return LoveLetterPreviewPage(noteId: noteId);
    },
  ),
  AppRoute(
    name: LoveRoutePaths.action,
    builder: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final noteId = args?['noteId'] as String;
      return LoveLetterActionPage(noteId: noteId);
    },
  ),
];
