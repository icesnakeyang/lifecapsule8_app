// lib/models/note_info.dart
import 'package:json_annotation/json_annotation.dart';

part 'encrypted_note.g.dart';

@JsonSerializable(explicitToJson: true)
class EncryptedNote {
  @JsonKey(name: 'noteId')
  final String noteId;

  @JsonKey(name: 'userId')
  final String userId;

  @JsonKey(name: 'updateAt')
  final DateTime updateAt;

  @JsonKey(name: 'iv')
  final String iv;

  @JsonKey(name: 'ciphertext')
  final String ciphertext;

  @JsonKey(name: 'salt')
  final String salt;

  @JsonKey(name: 'authTag')
  final String authTag;

  // 本地字段
  String? title;
  String? passwordHint;
  DateTime? scheduledOpenAt;
  bool isDeleted;

  EncryptedNote({
    required this.noteId,
    required this.userId,
    required this.updateAt,
    required this.iv,
    required this.ciphertext,
    required this.salt,
    required this.authTag,
    this.title,
    this.passwordHint,
    this.scheduledOpenAt,
    this.isDeleted = false, // 关键：默认 false
  });

  factory EncryptedNote.fromJson(Map<String, dynamic> json) =>
      _$EncryptedNoteFromJson(json);
  Map<String, dynamic> toJson() => _$EncryptedNoteToJson(this);

  // 必须加这个 copyWith！！
  EncryptedNote copyWith({
    String? title,
    String? passwordHint,
    DateTime? scheduledOpenAt,
    bool? isDeleted,
  }) {
    return EncryptedNote(
      noteId: noteId,
      userId: userId,
      updateAt: updateAt,
      iv: iv,
      ciphertext: ciphertext,
      salt: salt,
      authTag: authTag,
      title: title ?? this.title,
      passwordHint: passwordHint ?? this.passwordHint,
      scheduledOpenAt: scheduledOpenAt ?? this.scheduledOpenAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'NoteInfo(noteId: $noteId, title: $title, scheduled: $scheduledOpenAt)';
  }
}
