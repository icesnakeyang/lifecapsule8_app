import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// 支持多语言的通用日期时间显示组件
/// - 自动根据传入的 locale 适配当地时间格式
/// - 支持空值处理（显示默认文本）
/// - 可自定义显示模式（日期+时间/仅日期/仅时间）
class LocalizedDateTimeWidget extends StatefulWidget {
  /// 要显示的 DateTime（可为 null）
  final DateTime? dateTime;

  /// 用户当前的 Locale（如 Locale('zh')、Locale('en')）
  final Locale locale;

  /// 空值时显示的文本（默认 'N/A'）
  final String emptyText;

  /// 显示模式：dateTime（日期+时间）、date（仅日期）、time（仅时间）
  final DateTimeDisplayMode displayMode;

  /// 自定义格式（优先级最高，传入后忽略 displayMode，需符合 DateFormat 语法）
  final String? customFormat;

  const LocalizedDateTimeWidget({
    super.key,
    this.dateTime,
    required this.locale,
    this.emptyText = 'N/A',
    this.displayMode = DateTimeDisplayMode.dateTime,
    this.customFormat,
  });

  @override
  State<LocalizedDateTimeWidget> createState() =>
      _LocalizedDateTimeWidgetState();
}

/// 显示模式枚举
enum DateTimeDisplayMode {
  dateTime, // 日期+时间
  date, // 仅日期
  time, // 仅时间
}

class _LocalizedDateTimeWidgetState extends State<LocalizedDateTimeWidget> {
  @override
  void initState() {
    super.initState();
    // 初始化对应语言的日期格式化数据（确保中文/英文等格式正确）
    _initializeDateFormatting();
  }

  /// 初始化日期格式化数据（解决部分语言格式缺失问题）
  Future<void> _initializeDateFormatting() async {
    try {
      // 初始化当前 locale 对应的日期格式数据（如中文 zh、英文 en）
      await initializeDateFormatting(widget.locale.languageCode);
    } catch (e) {
      debugPrint('初始化日期格式失败：$e');
      // 失败时使用默认格式（不影响功能）
    }
  }

  /// 根据 locale 和显示模式获取格式化器
  DateFormat _getFormatter() {
    // 优先使用自定义格式
    if (widget.customFormat != null && widget.customFormat!.isNotEmpty) {
      return DateFormat(widget.customFormat, widget.locale.languageCode);
    }

    // 根据显示模式和 locale 选择默认格式
    switch (widget.displayMode) {
      case DateTimeDisplayMode.dateTime:
        // 中文：2025年12月01日 18:30:45；英文：Dec 01, 2025 6:30:45 PM
        return DateFormat.yMd(
          widget.locale.languageCode,
        ).addPattern(' ').add_jms();
      case DateTimeDisplayMode.date:
        // 中文：2025年12月01日；英文：Dec 01, 2025
        return DateFormat.yMMMd(widget.locale.languageCode);
      case DateTimeDisplayMode.time:
        // 中文：18:30:45；英文：6:30:45 PM
        return DateFormat.jms(widget.locale.languageCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 空值处理
    if (widget.dateTime == null) {
      return Text(widget.emptyText, style: const TextStyle(color: Colors.grey));
    }

    // 获取格式化器并格式化时间
    final formatter = _getFormatter();
    final formattedDateTime = formatter.format(widget.dateTime!);

    return Text(formattedDateTime);
  }
}
