// lib/theme/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

const String _themePrefKey = 'flutter.app_theme_id';

/// 直接使用 AppTheme 作为 state
class ThemeNotifier extends StateNotifier<AppTheme> {
  bool _isInitialized = false;

  ThemeNotifier() : super(AppTheme.dark) {
    _initTheme();
  } // 默认暗色主题

  Future<void> _initTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeId = prefs.getString(_themePrefKey) ?? 'dark';
    state = AppTheme.byId(savedThemeId);
    _isInitialized = true;
  }

  void setThemeById(String id) async {
    state = AppTheme.byId(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, id);
  }

  Future<void> toggleLightDark() async {
    final newTheme = state.id == 'dark' ? AppTheme.light : AppTheme.dark;
    state = newTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, newTheme.id);
  }

  bool get isInitialized => _isInitialized;
}

/// 当前 AppTheme（页面里 ref.watch(themeProvider) 拿语义颜色）
final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  return ThemeNotifier();
});

/// 当前 ThemeData（MaterialApp 用这个）
final themeDataProvider = Provider<ThemeData>((ref) {
  final appTheme = ref.watch(themeProvider);
  return appTheme.toThemeData();
});
