// lib/features/last_wishes/domain/last_wishes_list_item.dart

class LastWishesListItem {
  /// 对应 NoteBase.id
  final String id;

  /// 标题（通常可以从内容前一行或 meta.title 提取）
  final String title;

  /// 内容预览
  final String preview;

  /// 是否已启用
  final bool enabled;

  /// 等待年数
  final int? waitingYears;

  /// 更新时间（用于排序）
  final DateTime? updatedAt;

  const LastWishesListItem({
    required this.id,
    required this.title,
    required this.preview,
    required this.enabled,
    this.waitingYears,
    this.updatedAt,
  });

  LastWishesListItem copyWith({
    String? id,
    String? title,
    String? preview,
    bool? enabled,
    int? waitingYears,
    bool clearWaitingYears = false,
    DateTime? updatedAt,
  }) {
    return LastWishesListItem(
      id: id ?? this.id,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      enabled: enabled ?? this.enabled,
      waitingYears: clearWaitingYears
          ? null
          : (waitingYears ?? this.waitingYears),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isDraft => !enabled;

  bool get hasWaitingYears => waitingYears != null;

  String get waitingLabel {
    if (waitingYears == null) return '';
    final y = waitingYears!;
    return '$y year${y == 1 ? '' : 's'} waiting';
  }

  @override
  String toString() {
    return 'LastWishesListItem('
        'id: $id, '
        'title: $title, '
        'enabled: $enabled, '
        'waitingYears: $waitingYears'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LastWishesListItem &&
        other.id == id &&
        other.title == title &&
        other.preview == preview &&
        other.enabled == enabled &&
        other.waitingYears == waitingYears &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, preview, enabled, waitingYears, updatedAt);
  }
}
