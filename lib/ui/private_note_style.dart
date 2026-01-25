import 'package:flutter/material.dart';

class PrivateNoteStyle {
  static Brightness brightness(BuildContext context) =>
      MediaQuery.platformBrightnessOf(context);

  static Color bg(BuildContext context) {
    final b = brightness(context);
    return b == Brightness.dark
        ? const Color.fromARGB(255, 254, 254, 255) // 深色玻璃底
        : const Color.fromARGB(255, 129, 89, 220); // 浅色玻璃底
  }

  static Color border(BuildContext context) {
    final b = brightness(context);
    return b == Brightness.dark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.08);
  }

  static Color shadow(BuildContext context) {
    final b = brightness(context);
    return b == Brightness.dark
        ? Colors.black.withOpacity(0.35)
        : Colors.black.withOpacity(0.12);
  }

  static Color icon(BuildContext context) {
    final b = brightness(context);
    return b == Brightness.dark
        ? Colors.white.withOpacity(0.86)
        : Colors.black.withOpacity(0.78);
  }

  static Color text(BuildContext context) {
    final b = brightness(context);
    return b == Brightness.dark
        ? Colors.white.withOpacity(0.78)
        : Colors.black.withOpacity(0.68);
  }
}
