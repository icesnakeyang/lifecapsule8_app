class PrivateNote {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? serverNoteId;
  final bool isSynced;
  final bool isDeleted;
  final int version;
  final String type;

  const PrivateNote({
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

  PrivateNote copyWith({
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serverNoteId,
    bool? isSynced,
    bool? isDeleted,
    int? version,
    String? type,
  }) {
    return PrivateNote(
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
