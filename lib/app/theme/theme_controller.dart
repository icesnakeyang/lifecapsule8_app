import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'app_theme.dart';

const String _themePrefKey = 'lifecapsule.theme_id';

final appThemeProvider = NotifierProvider<ThemeController, AppTheme>(
  ThemeController.new,
);

final themeDataProvider = Provider<ThemeData>((ref) {
  final t = ref.watch(appThemeProvider);
  return t.toThemeData();
});

class ThemeController extends Notifier<AppTheme> {
  @override
  AppTheme build() {
    // 默认：Calm Dark（你原来默认暗色）
    final prefs = ref.read(sharedPrefsProvider);
    final savedId = prefs.getString(_themePrefKey) ?? AppTheme.calmDark.id;
    return AppTheme.byId(savedId);
  }

  Future<void> setThemeById(String id) async {
    final prefs = ref.read(sharedPrefsProvider);
    final t = AppTheme.byId(id);
    state = t;
    await prefs.setString(_themePrefKey, t.id);
  }

  Future<void> toggleLightDark() async {
    final prefs = ref.read(sharedPrefsProvider);
    final next = state.brightness == Brightness.dark
        ? AppTheme.calmLight
        : AppTheme.calmDark;
    state = next;
    await prefs.setString(_themePrefKey, next.id);
  }
}
