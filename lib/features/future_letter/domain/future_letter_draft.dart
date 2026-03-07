class FutureLetterDraft {
  const FutureLetterDraft({
    required this.noteId,
    required this.updatedAt,
    required this.content,

    // recipient
    this.userCode,
    this.userId,
    this.nickname,
    this.email,
    this.toName,
    this.fromName,

    // schedule (UTC ISO8601)
    this.sendAtIso,
  });

  final String noteId;
  final DateTime updatedAt;

  final String content;

  // Recipient
  final String? userCode;
  final String? userId;
  final String? nickname;
  final String? email;
  final String? toName;
  final String? fromName;

  // Schedule
  /// 必须是 UTC ISO8601 string
  final String? sendAtIso;

  FutureLetterDraft copyWith({
    DateTime? updatedAt,
    String? content,

    String? userCode,
    String? userId,
    String? nickname,
    String? email,
    String? toName,
    String? fromName,

    String? sendAtIso,

    bool clearRecipient = false,
    bool clearSendAt = false,
    bool clearEmail = false,
    bool clearToName = false,
    bool clearFromName = false,
  }) {
    return FutureLetterDraft(
      noteId: noteId,
      updatedAt: updatedAt ?? this.updatedAt,
      content: content ?? this.content,

      userCode: clearRecipient ? null : (userCode ?? this.userCode),
      userId: clearRecipient ? null : (userId ?? this.userId),
      nickname: clearRecipient ? null : (nickname ?? this.nickname),
      email: (clearRecipient || clearEmail) ? null : (email ?? this.email),
      toName: (clearRecipient || clearToName) ? null : (toName ?? this.toName),
      fromName: (clearRecipient || clearFromName)
          ? null
          : (fromName ?? this.fromName),

      sendAtIso: clearSendAt ? null : (sendAtIso ?? this.sendAtIso),
    );
  }
}
