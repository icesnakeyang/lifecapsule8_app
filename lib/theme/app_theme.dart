import 'package:flutter/material.dart';

class AppTheme {
  final String id; // 主题id，用于持久化/切换
  final String name; // 在设置页展示用
  final Brightness brightness;

  final Color surface; // 页面背景色（替代原 background）
  final Color onSurface; // 页面文本色（替代原 onBackground）
  final Color surfaceContainer; // 卡片/容器背景色（原 surface）
  final Color onSurfaceContainer; // 卡片文本色（原 onSurface）
  final Color surface2; // 次要表面/边框色（原 surface2）
  final Color onSurface2; // 次要表面文本色（原 onSurface2）

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;

  final Color primaryTimer;
  final Color onPrimaryTimer;
  final Color primaryTimerText;
  final Color onPrimaryTimerShadow;
  final Color dateTimeTimer;
  final Color onDateTimeTimer;
  final Color dateTimeTimerText;
  final Color dateTimeTimeronShadow;

  final Color tag1;
  final Color onTag1;
  final Color note;
  final Color onNote;
  final Color love;
  final Color onLove;
  final Color wishes;
  final Color onWishes;
  final Color inspiration;
  final Color onInspiration;
  final Color future;
  final Color onFuture;
  final Color history;
  final Color onHistory;
  final Color description;
  final Color onDescription;
  final Color error;
  final Color onError;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;

  final Color divider;

  const AppTheme({
    required this.id,
    required this.name,
    required this.brightness,
    required this.surface,
    required this.onSurface,
    required this.surfaceContainer,
    required this.onSurfaceContainer,
    required this.surface2,
    required this.onSurface2,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.primaryTimer,
    required this.onPrimaryTimer,
    required this.dateTimeTimer,
    required this.onDateTimeTimer,
    required this.primaryTimerText,
    required this.onPrimaryTimerShadow,
    required this.dateTimeTimerText,
    required this.dateTimeTimeronShadow,
    required this.tag1,
    required this.onTag1,
    required this.note,
    required this.onNote,
    required this.love,
    required this.onLove,
    required this.wishes,
    required this.onWishes,
    required this.inspiration,
    required this.onInspiration,
    required this.future,
    required this.onFuture,
    required this.history,
    required this.onHistory,
    required this.description,
    required this.onDescription,
    required this.error,
    required this.onError,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.divider,
  });

  /// 转成 Material ThemeData（彻底修复 TextTheme 错误，兼容所有 Flutter 版本）
  ThemeData toThemeData() {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primary.withValues(alpha: .15),
      onPrimaryContainer: primary,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondary.withValues(alpha: .15),
      onSecondaryContainer: secondary,
      error: const Color(0xFFB00020),
      onError: Colors.white,
      errorContainer: const Color(0xFFFCDDDF),
      onErrorContainer: const Color(0xFF410002),
      // 核心表面色（兼容所有版本）
      surface: surface, // 页面背景色
      onSurface: onSurface, // 页面文本色
      outline: surface2.withValues(alpha: .5),
      outlineVariant: surface2.withValues(alpha: .3),
      shadow: Colors.black.withValues(alpha: .1),
      scrim: Colors.black.withValues(alpha: .5),
      inverseSurface: onSurface,
      inversePrimary: primary.withValues(alpha: .8),
    );

    // 修复 TextTheme：直接使用 Flutter 内置的预设文本主题，避免 Typography 调用错误
    final textTheme =
        (brightness == Brightness.light
                ? ThemeData.light().textTheme
                : ThemeData.dark().textTheme)
            .apply(
              bodyColor: onSurface,
              displayColor: onSurface,
              decorationColor: onSurface,
              fontFamily: brightness == Brightness.light
                  ? 'Fredoka'
                  : 'Fredoka',
            );

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      cardColor: surfaceContainer,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainer,
        foregroundColor: onSurfaceContainer,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: textTheme, // 使用修复后的 TextTheme
      iconTheme: IconThemeData(color: onSurface, size: 24),
      buttonTheme: ButtonThemeData(
        buttonColor: primary,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // ========== 内置主题定义 ==========

  // 默认浅色主题：清新蓝调，温和舒适
  static const AppTheme light = AppTheme(
    id: 'light',
    name: 'Light',
    brightness: Brightness.light,
    // 基础表面色
    surface: Color(0xFFF8FAFC), // 页面背景色
    onSurface: Color(0xFF1E293B), // 页面文本色
    surfaceContainer: Color(0xFFFFFFFF), // 卡片/容器背景色
    onSurfaceContainer: Color(0xFF1E293B), // 卡片文本色
    surface2: Color(0xFFE2E8F0), // 次要表面/边框色
    onSurface2: Color(0xFF475569), // 次要表面文本色
    // 主色调（深蓝）
    primary: Color(0xFF4A90E2), // 明亮蓝，主按钮/强调色
    onPrimary: Colors.white, // 白色，主色上的文本
    // 辅助色（淡紫）
    secondary: Color(0xFF9333EA), // 淡紫，次要强调色
    onSecondary: Colors.white, // 白色，辅助色上的文本
    // 倒计时面板颜色
    primaryTimer: Color(0xFFEEF4FF), // 淡蓝，主倒计时背景
    onPrimaryTimer: Color(0xFF165DFF), // 主色，倒计时文本
    primaryTimerText: Color(0xff059B13),
    onPrimaryTimerShadow: Color(0xff2ED50D),
    dateTimeTimer: Color(0xFFF0FDF4), // 淡绿，日期时间背景
    onDateTimeTimer: Color(0xFF059669), // 深绿，日期时间文本
    dateTimeTimerText: Color(0xff00ff00),
    dateTimeTimeronShadow: Color(0xff00ff00),
    // 功能标签颜色
    tag1: Color(0xFF3B82F6), // 蓝，通用标签
    onTag1: Colors.white, // 白，通用标签文本
    note: Color(0xFF66B2FF), // 绿，笔记标签背景
    onNote: Color(0xFF065F46), // 深绿，笔记标签文本
    love: Color(0xFFFF99CC), // 粉，情书标签背景
    onLove: Colors.white, // 白，情书标签文本
    wishes: Color(0xFFFFCC80), // 橙，遗书标签背景
    onWishes: Colors.white, // 白，遗书标签文本
    inspiration: Color(0xFF6366F1), // 靛蓝，灵感标签背景
    onInspiration: Colors.white, // 白，灵感标签文本
    future: Color(0xFFEC4899), // 紫红，未来标签背景
    onFuture: Colors.white, // 白，未来标签文本
    history: Color(0xFF8B5CF6), // 紫，历史标签背景
    onHistory: Colors.white, // 白，历史标签文本
    description: Color(0xffdddddd),
    onDescription: Color(0xff888888),
    error: Color.fromARGB(255, 207, 69, 69),
    onError: Color(0xffffffff),
    success: Color.fromARGB(255, 71, 152, 21),
    onSuccess: Color(0xffffffff),
    warning: Color(0xffffffff),
    onWarning: Color(0xffffffff),
    divider: Color(0xFFE2E8F0),
  );

  // 深色主题：沉稳暗调，护眼不刺眼
  static const AppTheme dark = AppTheme(
    id: 'dark',
    name: 'Dark',
    brightness: Brightness.dark,
    // 基础表面色
    surface: Color(0xFF0F172A), // 页面背景色
    onSurface: Color(0xFFF1F5F9), // 页面文本色
    surfaceContainer: Color(0xFF1E293B), // 卡片/容器背景色
    onSurfaceContainer: Color(0xFFF1F5F9), // 卡片文本色
    surface2: Color(0xFF334155), // 次要表面/边框色
    onSurface2: Color(0xFF94A3B8), // 次要表面文本色
    // 主色调（亮绿）
    primary: Color(0xFF4ADE80), // 亮绿，主按钮/强调色
    onPrimary: Color(0xFF064E3B), // 深绿，主色上的文本
    // 辅助色（淡粉）
    secondary: Color(0xFFF472B6), // 淡粉，次要强调色
    onSecondary: Color(0xFF7C2D12), // 深棕，辅助色上的文本
    // 倒计时面板颜色
    primaryTimer: Color(0xFF134E4A), // 深绿，主倒计时背景
    onPrimaryTimer: Color(0xFF4ADE80), // 亮绿，倒计时文本
    primaryTimerText: Color(0xff47D45A),
    onPrimaryTimerShadow: Color(0xff3B7D23),
    dateTimeTimer: Color(0xFF1E3A8A), // 深蓝，日期时间背景
    onDateTimeTimer: Color(0xFFBFDBFE), // 淡蓝，日期时间文本
    dateTimeTimerText: Color(0xff00ff00),
    dateTimeTimeronShadow: Color(0xff00ff00),
    // 功能标签颜色
    tag1: Color(0xFF60A5FA), // 淡蓝，通用标签
    onTag1: Color(0xFF032f62), // 深蓝，通用标签文本
    note: Color(0xFF10B981), // 深绿，笔记标签背景
    onNote: Colors.white, // 白，笔记标签文本
    love: Color(0xFFEC4899), // 深粉，情书标签背景
    onLove: Colors.white, // 白，情书标签文本
    wishes: Color.fromARGB(255, 11, 148, 95), // 橙，遗书标签背景
    onWishes: Colors.white, // 白，遗书标签文本
    inspiration: Color(0xFF818CF8), // 淡靛蓝，灵感标签背景
    onInspiration: Color(0xFF1E1B4B), // 深靛蓝，灵感标签文本
    future: Color(0xFFF0ABFC), // 淡紫红，未来标签背景
    onFuture: Color(0xFF701A75), // 深紫红，未来标签文本
    history: Color(0xFFA78BFA), // 淡紫，历史标签背景
    onHistory: Color(0xFF3B0764), // 深紫，历史标签文本
    description: Color(0xffdddddd),
    onDescription: Color(0xff888888),
    error: Color.fromARGB(255, 158, 40, 77),
    onError: Color(0xffffffff),
    success: Color.fromARGB(255, 71, 152, 21),
    onSuccess: Color(0xffffffff),
    warning: Color.fromARGB(255, 207, 142, 21),
    onWarning: Color(0xffffffff),
    divider: Color(0xFFE2E8F0),
  );

  // 内置主题列表
  static const List<AppTheme> builtIn = <AppTheme>[light, dark];

  // 根据id获取主题
  static AppTheme byId(String id) {
    return builtIn.firstWhere((t) => t.id == id, orElse: () => light);
  }
}
