import 'package:flutter/material.dart';

String formatLocalDateTime(BuildContext context, DateTime dt) {
  final ml = MaterialLocalizations.of(context);

  final date = ml.formatMediumDate(dt);
  final time = ml.formatTimeOfDay(
    TimeOfDay.fromDateTime(dt),
    alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
  );

  return '$date $time';
}

// lib/utils/datetime_ext.dart
String toIso8601WithOffset(DateTime dt) {
  if (dt.isUtc) return dt.toIso8601String(); // 末尾自带 Z

  final s = dt.toIso8601String(); // 本地时间：不带 offset（Dart 的坑）
  final offset = dt.timeZoneOffset;

  final sign = offset.isNegative ? '-' : '+';
  final totalMinutes = offset.inMinutes.abs();
  final hh = (totalMinutes ~/ 60).toString().padLeft(2, '0');
  final mm = (totalMinutes % 60).toString().padLeft(2, '0');

  return '$s$sign$hh:$mm'; // 追加 +09:00 / +08:00
}
