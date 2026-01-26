class LocalNote {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? serverNoteId;
  final bool isSynced;
  final bool isDeleted;
  final int version;
  final String type;

  const LocalNote({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.serverNoteId,
    this.isSynced = false,
    this.isDeleted = false,
    this.version = 1,
    this.type = 'PRIVATE_NOTE',
  });

  factory LocalNote.fromJson(Map<String, dynamic> json) {
    return LocalNote(
      id: json['id'] as String,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      serverNoteId: json['serverNoteId'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      version: json['version'] as int? ?? 1,
      type: json['type'] as String? ?? 'PRIVATE_NOTE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'serverNoteId': serverNoteId,
      'isSynced': isSynced,
      'isDeleted': isDeleted,
      'version': version,
      'type': type,
    };
  }

  LocalNote copyWith({
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serverNoteId,
    bool? isSynced,
    bool? isDeleted,
    int? version,
    String? type,
  }) {
    return LocalNote(
      id: id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverNoteId: serverNoteId ?? this.serverNoteId,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
      type: type ?? this.type,
    );
  }
}
