// lib/provider/inspiration/inspiration_wall_provider.dart

class InspirationState {
  final bool loading;
  final String content;
  final String? error;
  final bool syncing;

  // UI state（可选：恢复光标、滚动、搜索）
  final int? cursorOffset;
  final double? scrollTop;

  final String noteId;

  const InspirationState({
    required this.loading,
    required this.syncing,
    required this.content,
    required this.noteId,
    this.error,
    this.cursorOffset,
    this.scrollTop,
  });

  factory InspirationState.initial({required String noteId}) {
    return InspirationState(
      loading: true,
      syncing: false,
      content: '',
      noteId: noteId,
    );
  }

  InspirationState copyWith({
    bool? loading,
    bool? syncing,
    String? content,
    String? error,
    bool clearError = false,
    int? cursorOffset,
    double? scrollTop,
  }) {
    return InspirationState(
      loading: loading ?? this.loading,
      syncing: syncing ?? this.syncing,
      content: content ?? this.content,
      noteId: noteId, // ✅ 永远不变
      error: clearError ? null : (error ?? this.error),
      cursorOffset: cursorOffset ?? this.cursorOffset,
      scrollTop: scrollTop ?? this.scrollTop,
    );
  }
}
