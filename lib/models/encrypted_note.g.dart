// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'encrypted_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EncryptedNote _$EncryptedNoteFromJson(Map<String, dynamic> json) =>
    EncryptedNote(
      noteId: json['noteId'] as String,
      userId: json['userId'] as String,
      updateAt: DateTime.parse(json['updateAt'] as String),
      iv: json['iv'] as String,
      ciphertext: json['ciphertext'] as String,
      salt: json['salt'] as String,
      authTag: json['authTag'] as String,
      title: json['title'] as String?,
      passwordHint: json['passwordHint'] as String?,
      scheduledOpenAt: json['scheduledOpenAt'] == null
          ? null
          : DateTime.parse(json['scheduledOpenAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );

Map<String, dynamic> _$EncryptedNoteToJson(EncryptedNote instance) =>
    <String, dynamic>{
      'noteId': instance.noteId,
      'userId': instance.userId,
      'updateAt': instance.updateAt.toIso8601String(),
      'iv': instance.iv,
      'ciphertext': instance.ciphertext,
      'salt': instance.salt,
      'authTag': instance.authTag,
      'title': instance.title,
      'passwordHint': instance.passwordHint,
      'scheduledOpenAt': instance.scheduledOpenAt?.toIso8601String(),
      'isDeleted': instance.isDeleted,
    };
