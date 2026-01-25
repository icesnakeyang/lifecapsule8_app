class FutureLetterDraft {
  const FutureLetterDraft({
    required this.noteId,
    required this.updatedAt,

    // recipient
    this.userCode,
    this.userId,
    this.nickname,
    this.email,
    this.toName,
    this.fromName,
    required this.content,

    // schedule
    this.sendAtIso, // ISO8601 local datetime string
    // flags
    this.clearRecipient = false,
    this.clearSendAt = false,
  });

  final String noteId;
  final DateTime updatedAt;

  // Recipient
  final String? userCode;
  final String? userId;
  final String? nickname;
  final String? email;
  final String? toName;
  final String? fromName;

  final String content;

  // Schedule
  final String? sendAtIso;

  // Clear flags
  final bool clearRecipient;
  final bool clearSendAt;

  FutureLetterDraft copyWith({
    DateTime? updatedAt,

    // recipient
    String? userCode,
    String? userId,
    String? nickname,
    String? email,
    String? toName,
    String? fromName,

    // schedule
    String? sendAtIso,

    // clear flags
    bool clearRecipient = false,
    bool clearSendAt = false,
    bool clearEmail = false,
    bool clearToName = false,
    bool clearFromName = false,
    String? content,
  }) {
    return FutureLetterDraft(
      noteId: noteId,
      updatedAt: updatedAt ?? this.updatedAt,

      // recipient
      userCode: clearRecipient ? null : (userCode ?? this.userCode),
      userId: clearRecipient ? null : (userId ?? this.userId),
      nickname: clearRecipient ? null : (nickname ?? this.nickname),
      email: (clearRecipient || clearEmail) ? null : (email ?? this.email),
      toName: (clearRecipient || clearToName) ? null : (toName ?? this.toName),
      fromName: (clearRecipient || clearFromName)
          ? null
          : (fromName ?? this.fromName),

      // schedule
      sendAtIso: clearSendAt ? null : (sendAtIso ?? this.sendAtIso),

      // flags
      clearRecipient: clearRecipient,
      clearSendAt: clearSendAt,
      content: content ?? this.content,
    );
  }

  Map<String, dynamic> toJson() => {
    'noteId': noteId,
    'updatedAt': updatedAt.toIso8601String(),

    // recipient
    'userCode': userCode,
    'userId': userId,
    'nickname': nickname,
    'email': email,
    'toName': toName,
    'fromName': fromName,

    // schedule
    'sendAtIso': sendAtIso,

    // flags
    'clearRecipient': clearRecipient,
    'clearSendAt': clearSendAt,
    'content': content,
  };

  static FutureLetterDraft fromJson(Map<String, dynamic> map) {
    return FutureLetterDraft(
      noteId: (map['noteId'] as String?) ?? '',
      updatedAt:
          DateTime.tryParse((map['updatedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),

      // recipient
      userCode: map['userCode'] as String?,
      userId: map['userId'] as String?,
      nickname: map['nickname'] as String?,
      email: map['email'] as String?,
      toName: map['toName'] as String?,
      fromName: map['fromName'] as String?,
      content: (map['content'] as String?) ?? '',

      // schedule
      sendAtIso: map['sendAtIso'] as String?,

      // flags
      clearRecipient: (map['clearRecipient'] as bool?) ?? false,
      clearSendAt: (map['clearSendAt'] as bool?) ?? false,
    );
  }
}
