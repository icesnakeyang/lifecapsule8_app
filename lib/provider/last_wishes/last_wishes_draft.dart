// lib/provider/last_wishes/last_wishes_draft.dart

class LastWishesDraft {
  const LastWishesDraft({
    required this.noteId,
    required this.updatedAt,
    this.content = '',
    this.destination = 'PERSON', // 'PERSON' | 'WORLD'
    this.recipientEmail,
    this.waitingYears,
    this.enabled = false,
    this.messageNote,
  });

  final String noteId;
  final DateTime updatedAt;

  /// 遗言正文（本地明文草稿）
  final String content;

  /// 去向：PERSON / WORLD（WORLD 目前可灰显，但字段可以先保留）
  final String destination;

  /// 收件人 email（仅 destination==PERSON）
  final String? recipientEmail;

  /// 等待周期（年） 1/5/10/20
  final int? waitingYears;

  /// 是否已确认启用（预览确认后 true）
  final bool enabled;

  /// 给收件人一句话（可选）
  final String? messageNote;

  LastWishesDraft copyWith({
    DateTime? updatedAt,
    String? content,
    String? destination,
    String? recipientEmail,
    int? waitingYears,
    bool? enabled,
    String? messageNote,

    // clears
    bool clearRecipientEmail = false,
    bool clearWaitingYears = false,
    bool clearMessageNote = false,
  }) {
    return LastWishesDraft(
      noteId: noteId,
      updatedAt: updatedAt ?? this.updatedAt,
      content: content ?? this.content,
      destination: destination ?? this.destination,
      recipientEmail: clearRecipientEmail
          ? null
          : (recipientEmail ?? this.recipientEmail),
      waitingYears: clearWaitingYears
          ? null
          : (waitingYears ?? this.waitingYears),
      enabled: enabled ?? this.enabled,
      messageNote: clearMessageNote ? null : (messageNote ?? this.messageNote),
    );
  }

  Map<String, dynamic> toJson() => {
    'noteId': noteId,
    'updatedAt': updatedAt.toIso8601String(),
    'content': content,
    'destination': destination,
    'recipientEmail': recipientEmail,
    'waitingYears': waitingYears,
    'enabled': enabled,
    'messageNote': messageNote,
  };

  static LastWishesDraft fromJson(Map<String, dynamic> map) {
    return LastWishesDraft(
      noteId: (map['noteId'] as String?) ?? '',
      updatedAt:
          DateTime.tryParse((map['updatedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      content: (map['content'] as String?) ?? '',
      destination: ((map['destination'] as String?) ?? 'PERSON').toUpperCase(),
      recipientEmail: map['recipientEmail'] as String?,
      waitingYears: (map['waitingYears'] as num?)?.toInt(),
      enabled: (map['enabled'] as bool?) ?? false,
      messageNote: map['messageNote'] as String?,
    );
  }
}
