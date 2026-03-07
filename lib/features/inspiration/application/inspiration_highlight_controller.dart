// lib/features/inspiration/presentation/search_highlight_controller.dart
import 'package:flutter/material.dart';

class SearchHighlightController extends TextEditingController {
  SearchHighlightController({
    super.text,
    this.searchQuery,
    this.matchStarts = const [],
    this.currentMatchIndex = -1,
    this.hintText,
    this.hintStyle,
  });

  String? searchQuery;
  List<int> matchStarts;
  int currentMatchIndex;

  final String? hintText;
  final TextStyle? hintStyle;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool withComposing = false,
  }) {
    final t = text;
    final q = searchQuery ?? '';

    if (t.isEmpty && q.isEmpty) {
      if (hintText != null) {
        return TextSpan(text: hintText, style: hintStyle ?? style);
      }
      return const TextSpan(text: '');
    }

    if (q.isEmpty || matchStarts.isEmpty) {
      return TextSpan(text: t, style: style);
    }

    final spans = <InlineSpan>[];
    int index = 0;

    for (int i = 0; i < matchStarts.length; i++) {
      final start = matchStarts[i];
      final end = (start + q.length).clamp(0, t.length);

      if (start > index) {
        spans.add(TextSpan(text: t.substring(index, start)));
      }

      final isCurrent = i == currentMatchIndex;
      spans.add(
        TextSpan(
          text: t.substring(start, end),
          style: style?.copyWith(
            backgroundColor: isCurrent
                ? Colors.white.withOpacity(0.28)
                : Colors.white.withOpacity(0.18),
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      );

      index = end;
    }

    if (index < t.length) {
      spans.add(TextSpan(text: t.substring(index)));
    }

    return TextSpan(style: style, children: spans);
  }
}
