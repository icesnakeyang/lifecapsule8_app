import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final loveLetterListControllerProvider =
    AsyncNotifierProvider<LoveLetterListController, LoveLetterListState>(
      LoveLetterListController.new,
    );

class LoveLetterListItem {
  final String noteId;
  final String title;
  final DateTime updatedAt;
  final DateTime createdAt;

  const LoveLetterListItem({
    required this.noteId,
    required this.title,
    required this.updatedAt,
    required this.createdAt,
  });
}

class LoveLetterListState {
  final bool loading;
  final String? error;
  final List<LoveLetterListItem> items;

  const LoveLetterListState({
    this.loading = true,
    this.error,
    this.items = const [],
  });

  LoveLetterListState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<LoveLetterListItem>? items,
  }) {
    return LoveLetterListState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
    );
  }
}

class LoveLetterListController extends AsyncNotifier<LoveLetterListState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);
  static const _uuid = Uuid();

  @override
  Future<LoveLetterListState> build() async {
    final base = const LoveLetterListState(loading: true);
    return _loadInternal(base);
  }

  Future<void> refresh() async {
    final cur = state.value ?? const LoveLetterListState();
    state = AsyncData(cur.copyWith(loading: true, clearError: true));
    final loaded = await _loadInternal(state.value ?? cur);
    state = AsyncData(loaded);
  }

  /// ✅ A 方案：只生成 id，不写 notes_box（避免空笔记垃圾）
  String createNewNoteId() => 'love_${_uuid.v4()}';

  Future<void> deleteLetter(String noteId) async {
    final cur = state.value ?? const LoveLetterListState();
    state = AsyncData(cur.copyWith(clearError: true));
    try {
      await _repo.markDeleted(noteId);
      await refresh();
    } catch (e) {
      state = AsyncData((state.value ?? cur).copyWith(error: e.toString()));
    }
  }

  Future<LoveLetterListState> _loadInternal(LoveLetterListState base) async {
    try {
      final letters = await _repo.list(
        kind: NoteKind.loveLetter,
        includeDeleted: false,
      );

      final sorted = [...letters]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final items = sorted.map(_toItem).toList();

      return base.copyWith(loading: false, items: items, clearError: true);
    } catch (e) {
      return base.copyWith(loading: false, error: e.toString());
    }
  }

  LoveLetterListItem _toItem(NoteBase n) {
    final raw = (n.content ?? '').trim();
    final titleLine = raw.isEmpty ? '' : raw.split('\n').first.trim();

    return LoveLetterListItem(
      noteId: n.id,
      title: titleLine.isEmpty ? '(Empty letter)' : titleLine,
      updatedAt: n.updatedAt,
      createdAt: n.createdAt,
    );
  }
}
