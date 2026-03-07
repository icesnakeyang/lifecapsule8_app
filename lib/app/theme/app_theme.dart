import 'package:flutter/material.dart';

@immutable
class ScenePalette {
  final Color primary;
  final Color accent;
  final Color onPrimary;
  final Color onSurfaceDim;
  final Color gradientStart;
  final Color gradientEnd;

  const ScenePalette({
    required this.primary,
    required this.accent,
    required this.onPrimary,
    required this.onSurfaceDim,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

@immutable
class AppTheme {
  final String id;
  final String name;
  final Brightness brightness;

  // App 基调（克制、安静）
  final Color surface; // 页面背景
  final Color onSurface; // 正文文字
  final Color surfaceContainer; // 卡片/容器背景
  final Color onSurfaceContainer; // 卡片文字
  final Color outline; // 分割线/边框

  // 品牌主色
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;

  // 语义色
  final Color error;
  final Color onError;
  final Color success;
  final Color warning;
  final Color onWarning;

  // 场景色板（“分类=氛围”）
  final ScenePalette privateNote;
  final ScenePalette loveLetter;
  final ScenePalette wishes;
  final ScenePalette inspiration;
  final ScenePalette future;
  final ScenePalette history;

  const AppTheme({
    required this.id,
    required this.name,
    required this.brightness,
    required this.surface,
    required this.onSurface,
    required this.surfaceContainer,
    required this.onSurfaceContainer,
    required this.outline,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.error,
    required this.onError,
    required this.success,
    required this.warning,
    required this.onWarning,
    required this.privateNote,
    required this.loveLetter,
    required this.wishes,
    required this.inspiration,
    required this.future,
    required this.history,
  });

  ThemeData toThemeData() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );

    final scheme = baseScheme.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      error: error,
      onError: onError,
      surface: surface,
      onSurface: onSurface,
      outline: outline,
      // 这些 container 颜色你原来有逻辑，我保留你的风格
      primaryContainer: Color.alphaBlend(primary.withOpacity(0.12), surface),
      onPrimaryContainer: primary,
      secondaryContainer: Color.alphaBlend(
        secondary.withOpacity(0.12),
        surface,
      ),
      onSecondaryContainer: secondary,
      errorContainer: Color.alphaBlend(error.withOpacity(0.14), surface),
      onErrorContainer: error,
    );

    final baseTextTheme =
        (brightness == Brightness.light
                ? ThemeData.light().textTheme
                : ThemeData.dark().textTheme)
            .apply(
              bodyColor: onSurface,
              displayColor: onSurface,
              decorationColor: onSurface,
              fontFamily: 'Quicksand',
            );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: baseTextTheme,
      dividerColor: outline,

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withOpacity(0.55)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  // ========== 内置主题 ==========
  static const AppTheme calmLight = AppTheme(
    id: 'calm_light',
    name: 'Calm Light',
    brightness: Brightness.light,

    // 更干净纸感背景（减少粉感）
    surface: Color(0xFFF4F6FB),
    onSurface: Color(0xFF1C1F2E),
    surfaceContainer: Color(0xFFFFFFFF),
    onSurfaceContainer: Color(0xFF1C1F2E),
    outline: Color(0x1A1C1F2E),

    // 品牌紫更克制
    primary: Color(0xFF6C63D9),
    onPrimary: Colors.white,
    secondary: Color(0xFF8B82F2),
    onSecondary: Colors.white,

    error: Color(0xFFD92D20),
    onError: Colors.white,
    success: Color(0xFF0F9D58),
    warning: Color(0xFFE59E0B),
    onWarning: Color.fromARGB(255, 252, 252, 252),

    privateNote: ScenePalette(
      primary: Color(0xFF4F7EF7),
      accent: Color(0xFF3CCF91),
      onPrimary: Colors.white,
      onSurfaceDim: Color(0xB3FFFFFF),
      gradientStart: Color(0x664F7EF7),
      gradientEnd: Color(0xFF141A2F),
    ),

    loveLetter: ScenePalette(
      primary: Color(0xFFD9468A),
      accent: Color(0xFFF28BB3),
      onPrimary: Colors.white,
      onSurfaceDim: Color(0xB3FFFFFF),
      gradientStart: Color(0x66D9468A),
      gradientEnd: Color(0xFF2C0E20),
    ),

    wishes: ScenePalette(
      primary: Color(0xFFE07A2E),
      accent: Color(0xFFF5B041),
      onPrimary: Colors.white,
      onSurfaceDim: Color(0xB3FFFFFF),
      gradientStart: Color(0x66E07A2E),
      gradientEnd: Color(0xFF2B1C12),
    ),

    inspiration: ScenePalette(
      primary: Color(0xFF7A5AF8),
      accent: Color(0xFFA78BFA),
      onPrimary: Colors.white,
      onSurfaceDim: Color(0xB3FFFFFF),
      gradientStart: Color(0x667A5AF8),
      gradientEnd: Color(0xFF1E1A3D),
    ),

    future: ScenePalette(
      primary: Color(0xFF0EA5A4),
      accent: Color(0xFF67E8F9),
      onPrimary: Colors.white,
      onSurfaceDim: Color(0xB3FFFFFF),
      gradientStart: Color(0x660EA5A4),
      gradientEnd: Color(0xFF101E27),
    ),

    history: ScenePalette(
      primary: Color(0xFF7C3AED),
      accent: Color(0xFFC084FC),
      onPrimary: Colors.white,
      onSurfaceDim: Color(0xB3FFFFFF),
      gradientStart: Color(0x667C3AED),
      gradientEnd: Color(0xFF1B1234),
    ),
  );

  static const AppTheme calmDark = AppTheme(
    id: 'calm_dark',
    name: 'Calm Dark',
    brightness: Brightness.dark,

    // 更深蓝灰夜色（减少纯黑）
    surface: Color(0xFF0F1426),
    onSurface: Color(0xFFE8EBF5),
    surfaceContainer: Color(0xFF161C33),
    onSurfaceContainer: Color(0xFFE8EBF5),
    outline: Color(0x33E8EBF5),

    primary: Color(0xFF9A8CFF),
    onPrimary: Color(0xFF1B1538),
    secondary: Color(0xFF4FD1C5),
    onSecondary: Color(0xFF052A2C),

    error: Color(0xFFFF6B6B),
    onError: Colors.white,
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    onWarning: Color.fromARGB(255, 152, 22, 2),

    privateNote: ScenePalette(
      primary: Color(0xFF5B8CFF),
      accent: Color(0xFF3CCF91),
      onPrimary: Color(0xFF061230),
      onSurfaceDim: Color(0xB3FFFFFF),
      gradientStart: Color(0x664F7EF7),
      gradientEnd: Color(0xFF0F1426),
    ),

    loveLetter: ScenePalette(
      primary: Color(0xFFF472B6),
      accent: Color(0xFFF9A8D4),
      onPrimary: Color.fromARGB(255, 246, 228, 238),
      onSurfaceDim: Color(0xB3FFFFFF),
      gradientStart: Color(0x66F472B6),
      gradientEnd: Color(0xFF2A0E22),
    ),

    wishes: ScenePalette(
      primary: Color.fromARGB(255, 1, 72, 21),
      accent: Color.fromARGB(255, 13, 131, 116),
      onPrimary: Color.fromARGB(255, 209, 236, 228),
      onSurfaceDim: Color(0xB3FFFFFF),
      gradientStart: Color.fromARGB(255, 4, 123, 79),
      gradientEnd: Color.fromARGB(255, 3, 44, 32),
    ),

    inspiration: ScenePalette(
      primary: Color(0xFFC4B5FD),
      accent: Color(0xFFA78BFA),
      onPrimary: Color.fromARGB(255, 249, 249, 255),
      onSurfaceDim: Color(0xB3FFFFFF),
      gradientStart: Color.fromARGB(102, 191, 70, 242),
      gradientEnd: Color.fromARGB(255, 90, 16, 95),
    ),

    future: ScenePalette(
      primary: Color(0xFF67E8F9),
      accent: Color(0xFF894EAF),
      onPrimary: Color.fromARGB(255, 245, 254, 255),
      onSurfaceDim: Color(0xB3FFFFFF),
      gradientStart: Color(0xFF4C1F8D),
      gradientEnd: Color(0xFF531261),
    ),

    history: ScenePalette(
      primary: Color(0xFFD8B4FE),
      accent: Color(0xFFC084FC),
      onPrimary: Color(0xFF1E1238),
      onSurfaceDim: Color(0xB3FFFFFF),
      gradientStart: Color(0x667C3AED),
      gradientEnd: Color(0xFF1B1234),
    ),
  );

  static const List<AppTheme> builtIn = <AppTheme>[calmLight, calmDark];

  static AppTheme byId(String id) {
    return builtIn.firstWhere((t) => t.id == id, orElse: () => calmLight);
  }
}
