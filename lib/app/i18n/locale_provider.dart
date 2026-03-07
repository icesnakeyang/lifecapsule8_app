import 'dart:ui';

import 'package:flutter_riverpod/legacy.dart';

final localeProvider = StateNotifierProvider<LocaleController, Locale?>(
  (ref) => LocaleController(),
);

class LocaleController extends StateNotifier<Locale?> {
  LocaleController() : super(const Locale('en'));

  void setLocale(Locale locale) {
    state = locale;
  }

  void clear() {
    state = null;
  }
}
