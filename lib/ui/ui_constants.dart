import 'package:flutter/material.dart';

/// ===== Private Note（私密笔记）专用 UI 常量 =====
///
/// 不使用 themeProvider
/// 目的：
/// - 私密、克制、不抢主功能
/// - 在浅色背景下“若隐若现”
/// - 长期稳定，不随主题变化
///
class PrivateNoteUI {
  static const Color bg = Color(0xFFF4F5F7); // 纸张灰
  static const Color border = Color(0xFFCDD1D6); // 低对比边框
  static const Color icon = Color(0xFF4A4F55); // 深灰
  static const Color text = Color(0xFF4A4F55); // 与 icon 保持一致
}
