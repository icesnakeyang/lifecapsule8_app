// lib/features/future_letter/domain/future_letter_draft.dart
class FutureLetterDraft {
  final String noteId;
  final String content;
  final String? sendAtIso;
  final String? userCode;
  final String? email;
  final String? toName;
  final String? fromName;
  final DateTime updatedAt;

  const FutureLetterDraft({
    required this.noteId,
    required this.content,
    required this.updatedAt,
    this.sendAtIso,
    this.userCode,
    this.email,
    this.toName,
    this.fromName,
  });

  FutureLetterDraft copyWith({
    String? noteId,
    String? content,
    String? sendAtIso,
    String? userCode,
    String? email,
    String? toName,
    String? fromName,
    DateTime? updatedAt,
  }) {
    return FutureLetterDraft(
      noteId: noteId ?? this.noteId,
      content: content ?? this.content,
      sendAtIso: sendAtIso ?? this.sendAtIso,
      userCode: userCode ?? this.userCode,
      email: email ?? this.email,
      toName: toName ?? this.toName,
      fromName: fromName ?? this.fromName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasRecipient =>
      (userCode ?? '').trim().isNotEmpty || (email ?? '').trim().isNotEmpty;
}
