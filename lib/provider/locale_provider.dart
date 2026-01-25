import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale_code';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // 默认英文，异步再加载用户上次选择
    _loadSavedLocale();
    return const Locale('en');
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleKey);

    if (code == null) return;

    switch (code) {
      case 'zh':
        state = const Locale('zh');
        break;
      case 'en':
      default:
        state = const Locale('en');
        break;
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
