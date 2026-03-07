import 'note_kind.dart';

class NoteBase {
  final String id;
  final String userId;
  final NoteKind kind;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? content; // 明文内容（未加密时）
  final String? enc; // 加密内容（compact string）
  final String? serverNoteId;

  final bool isSynced;
  final bool isDeleted;
  final int version;

  final Map<String, dynamic> meta;

  const NoteBase({
    required this.id,
    required this.userId,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
    this.content,
    this.enc,
    this.serverNoteId,
    this.isSynced = false,
    this.isDeleted = false,
    this.version = 1,
    this.meta = const {},
  });

  NoteBase copyWith({
    String? userId,
    NoteKind? kind,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? content,
    String? enc,
    String? serverNoteId,
    bool? isSynced,
    bool? isDeleted,
    int? version,
    Map<String, dynamic>? meta,
  }) {
    return NoteBase(
      id: id,
      userId: userId ?? this.userId,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      content: content ?? this.content,
      enc: enc ?? this.enc,
      serverNoteId: serverNoteId ?? this.serverNoteId,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'kind': kind.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'content': content,
    'enc': enc,
    'serverNoteId': serverNoteId,
    'isSynced': isSynced,
    'isDeleted': isDeleted,
    'version': version,
    'meta': meta,
  };

  factory NoteBase.fromJson(Map<String, dynamic> json) {
    final kindName = (json['kind'] as String?) ?? NoteKind.privateNote.name;
    final kind = NoteKind.values.firstWhere(
      (e) => e.name == kindName,
      orElse: () => NoteKind.privateNote,
    );

    return NoteBase(
      id: json['id'] as String,
      userId: (json['userId'] as String?) ?? '',
      kind: kind,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      content: json['content'] as String?,
      enc: json['enc'] as String?,
      serverNoteId: json['serverNoteId'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      version: json['version'] as int? ?? 1,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
