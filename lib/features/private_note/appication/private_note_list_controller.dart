import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

class PrivateNoteListItem {
  final String id;
  final String title;
  final DateTime updatedAt;
  final bool isSynced;

  const PrivateNoteListItem({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.isSynced,
  });
}

class PrivateNoteListState {
  final bool loading;
  final String? error;
  final List<PrivateNoteListItem> items;

  const PrivateNoteListState({
    this.loading = true,
    this.error,
    this.items = const [],
  });

  PrivateNoteListState copyWith({
    bool? loading,
    String? error,
    List<PrivateNoteListItem>? items,
    bool clearError = false,
  }) {
    return PrivateNoteListState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
    );
  }
}

final privateNoteListControllerProvider =
    NotifierProvider<PrivateNoteListController, PrivateNoteListState>(() {
      return PrivateNoteListController();
    });

class PrivateNoteListController extends Notifier<PrivateNoteListState> {
  bool _inited = false;
  NotesRepository get _repo => ref.read(notesRepositoryProvider);
  StreamSubscription<List<NoteBase>>? _sub;

  @override
  PrivateNoteListState build() {
    if (!_inited) {
      _inited = true;

      Future.microtask(() async {
        if (!ref.mounted) return;
        await refresh();
        _listen();
      });

      ref.onDispose(() => _sub?.cancel());
    }
    return const PrivateNoteListState(loading: true);
  }

  void _listen() {
    _sub?.cancel();
    state = state.copyWith(loading: true, clearError: true);

    _sub = _repo
        .watchList(kind: NoteKind.privateNote)
        .listen(
          (notes) {
            final items = notes.map(_toItem).toList();
            state = state.copyWith(
              loading: false,
              items: items,
              clearError: true,
            );
          },
          onError: (e, _) {
            state = state.copyWith(loading: false, error: e.toString());
          },
        );
  }

  PrivateNoteListItem _toItem(NoteBase n) {
    final text = (n.content ?? '').trim();
    final title = text.isEmpty ? '(Empty note)' : text.split('\n').first.trim();
    return PrivateNoteListItem(
      id: n.id,
      title: title,
      updatedAt: n.updatedAt,
      isSynced: n.isSynced,
    );
  }

  Future<void> refresh() async {
    _listen();
  }

  Future<void> deleteById(String id) async {
    await _repo.markDeleted(id);
  }
}
