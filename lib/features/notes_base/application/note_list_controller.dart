// lib/features/notes/application/note_list_controller.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/note_base.dart';
import '../domain/note_kind.dart';
import '../data/notes_repository.dart';
import 'notes_providers.dart';

class NoteListItem {
  final String id;
  final String title;
  final DateTime updatedAt;
  final bool isSynced;
  final NoteKind kind;

  const NoteListItem({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.isSynced,
    required this.kind,
  });
}

class NoteListState {
  final bool loading;
  final List<NoteListItem> items;
  final String? error;

  const NoteListState({this.loading = true, this.items = const [], this.error});

  NoteListState copyWith({
    bool? loading,
    List<NoteListItem>? items,
    String? error,
  }) {
    return NoteListState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: error,
    );
  }
}

final noteListControllerProvider =
    NotifierProvider<NoteListController, NoteListState>(() {
      return NoteListController();
    });

class NoteListController extends Notifier<NoteListState> {
  StreamSubscription<List<NoteBase>>? _sub;

  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  @override
  NoteListState build() {
    _watch(kind: NoteKind.privateNote); // 默认先做 privateNote list
    ref.onDispose(() => _sub?.cancel());
    return const NoteListState(loading: true);
  }

  void _watch({NoteKind? kind}) {
    _sub?.cancel();
    state = state.copyWith(loading: true, error: null);

    _sub = _repo
        .watchList(kind: kind)
        .listen(
          (notes) {
            final items = notes.map(_toItem).toList();
            state = state.copyWith(loading: false, items: items, error: null);
          },
          onError: (e, _) {
            state = state.copyWith(loading: false, error: e.toString());
          },
        );
  }

  NoteListItem _toItem(NoteBase n) {
    final text = (n.content ?? '').trim();
    final title = text.isEmpty ? '(Empty note)' : text.split('\n').first.trim();

    return NoteListItem(
      id: n.id,
      title: title,
      updatedAt: n.updatedAt,
      isSynced: n.isSynced,
      kind: n.kind,
    );
  }

  Future<void> refresh() async {
    _watch(kind: NoteKind.privateNote);
  }

  Future<void> deleteById(String id) async {
    await _repo.markDeleted(id);
    // watchList 会自动刷新
  }
}
