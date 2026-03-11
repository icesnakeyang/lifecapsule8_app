// lib/features/last_wishes/domain/last_wishes_draft.dart

class LastWishesDraft {
  final String noteId;

  /// 用户写的内容
  final String content;

  /// 收件人
  final String recipientEmail;

  /// 等待年数（用户自定义）
  final int? waitingYears;

  /// 给收件人的附加说明
  final String messageNote;

  /// 是否启用
  final bool enabled;

  const LastWishesDraft({
    required this.noteId,
    this.content = '',
    this.recipientEmail = '',
    this.waitingYears,
    this.messageNote = '',
    this.enabled = false,
  });

  factory LastWishesDraft.empty({String noteId = 'last_wishes'}) {
    return LastWishesDraft(noteId: noteId);
  }

  LastWishesDraft copyWith({
    String? noteId,
    String? content,
    String? recipientEmail,
    int? waitingYears,
    bool clearWaitingYears = false,
    String? messageNote,
    bool? enabled,
  }) {
    return LastWishesDraft(
      noteId: noteId ?? this.noteId,
      content: content ?? this.content,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      waitingYears: clearWaitingYears
          ? null
          : (waitingYears ?? this.waitingYears),
      messageNote: messageNote ?? this.messageNote,
      enabled: enabled ?? this.enabled,
    );
  }

  bool get hasContent => content.trim().isNotEmpty;

  bool get hasRecipient => recipientEmail.trim().isNotEmpty;

  bool get hasWaitingYears => waitingYears != null;

  Map<String, dynamic> toDebugMap() {
    return {
      'noteId': noteId,
      'content': content,
      'recipientEmail': recipientEmail,
      'waitingYears': waitingYears,
      'messageNote': messageNote,
      'enabled': enabled,
    };
  }

  @override
  String toString() => 'LastWishesDraft(${toDebugMap()})';
}
