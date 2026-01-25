// lib/provider/love_letter/love_letter_draft.dart

class LoveLetterDraft {
  const LoveLetterDraft({
    required this.noteId,
    required this.updatedAt,

    this.content,

    // recipient
    this.toType, // 'USER' | 'EMAIL'
    this.userCode,
    this.userId,
    this.nickname,
    this.email,
    this.toName,
    this.fromName,

    // schedule
    this.sendAtIso, // ISO8601 local datetime string
    this.sendMode, // 'SPECIFIC_TIME' | 'PRIMARY_COUNTDOWN' | 'INSTANTLY'
    // passcode
    this.passcodeMode, // 'NONE' | 'PASSCODE' | 'QA'
    this.passcode, // PASSCODE: 'xxxx' ; QA: json string
    // flags
    this.clearRecipient = false,
    this.clearSendAt = false,
    this.clearSendMode = false,
    this.clearPasscode = false,
  });

  final String noteId;
  final DateTime updatedAt;

  final String? content;

  // Recipient
  final String? toType;
  final String? userCode;
  final String? userId;
  final String? nickname;
  final String? email;
  final String? toName;
  final String? fromName;

  // Schedule
  final String? sendAtIso;
  final String? sendMode;

  // Passcode
  final String? passcodeMode; // NONE | PASSCODE | QA
  final String? passcode; // PASSCODE raw; QA json string

  // Clear flags
  final bool clearRecipient;
  final bool clearSendAt;
  final bool clearSendMode;
  final bool clearPasscode;

  LoveLetterDraft copyWith({
    DateTime? updatedAt,
    String? content,
    bool clearContent = false,

    // recipient
    String? toType,
    String? userCode,
    String? userId,
    String? nickname,
    String? email,
    String? toName,
    String? fromName,

    // schedule
    String? sendAtIso,
    String? sendMode,

    // passcode
    String? passcodeMode,
    String? passcode,

    // clear flags
    bool clearRecipient = false,
    bool clearSendAt = false,
    bool clearSendMode = false,
    bool clearEmail = false,
    bool clearToName = false,
    bool clearFromName = false,
    bool clearPasscode = false,
  }) {
    return LoveLetterDraft(
      noteId: noteId,
      updatedAt: updatedAt ?? this.updatedAt,

      content: clearContent ? null : (content ?? this.content),

      // recipient
      toType: clearRecipient ? null : (toType ?? this.toType),
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
      sendMode: clearSendMode ? null : (sendMode ?? this.sendMode),

      // passcode
      passcodeMode: clearPasscode ? null : (passcodeMode ?? this.passcodeMode),
      passcode: clearPasscode ? null : (passcode ?? this.passcode),

      // flags
      clearRecipient: clearRecipient,
      clearSendAt: clearSendAt,
      clearSendMode: clearSendMode,
      clearPasscode: clearPasscode,
    );
  }

  Map<String, dynamic> toJson() => {
    'noteId': noteId,
    'updatedAt': updatedAt.toIso8601String(),
    'content': content,

    // recipient
    'toType': toType,
    'userCode': userCode,
    'userId': userId,
    'nickname': nickname,
    'email': email,
    'toName': toName,
    'fromName': fromName,

    // schedule
    'sendAtIso': sendAtIso,
    'sendMode': sendMode,

    // passcode
    'passcodeMode': passcodeMode,
    'passcode': passcode,

    // flags
    'clearRecipient': clearRecipient,
    'clearSendAt': clearSendAt,
    'clearSendMode': clearSendMode,
    'clearPasscode': clearPasscode,
  };

  static LoveLetterDraft fromJson(Map<String, dynamic> map) {
    return LoveLetterDraft(
      noteId: (map['noteId'] as String?) ?? '',
      updatedAt:
          DateTime.tryParse((map['updatedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),

      content: map['content'] as String?,

      // recipient
      toType: map['toType'] as String?,
      userCode: map['userCode'] as String?,
      userId: map['userId'] as String?,
      nickname: map['nickname'] as String?,
      email: map['email'] as String?,
      toName: map['toName'] as String?,
      fromName: map['fromName'] as String?,

      // schedule
      sendAtIso: map['sendAtIso'] as String?,
      sendMode: map['sendMode'] as String?,

      // passcode
      passcodeMode: map['passcodeMode'] as String?,
      passcode: map['passcode'] as String?,

      // flags
      clearRecipient: (map['clearRecipient'] as bool?) ?? false,
      clearSendAt: (map['clearSendAt'] as bool?) ?? false,
      clearSendMode: (map['clearSendMode'] as bool?) ?? false,
      clearPasscode: (map['clearPasscode'] as bool?) ?? false,
    );
  }
}
