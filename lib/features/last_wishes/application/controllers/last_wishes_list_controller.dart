import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final lastWishesListControllerProvider =
    StateNotifierProvider<LastWishesListController, LastWishesListState>((ref) {
      return LastWishesListController(ref);
    });

class LastWishesListState {
  final bool loading;
  final String query;
  final String? error;
  final List<NoteBase> items;

  const LastWishesListState({
    this.loading = false,
    this.query = '',
    this.error,
    this.items = const [],
  });

  LastWishesListState copyWith({
    bool? loading,
    String? query,
    String? error,
    bool clearError = false,
    List<NoteBase>? items,
  }) {
    return LastWishesListState(
      loading: loading ?? this.loading,
      query: query ?? this.query,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
    );
  }

  List<NoteBase> get filtered {
    final q = query.trim().toLowerCase();

    final list = items.where((n) {
      if (q.isEmpty) return true;
      final content = (n.content ?? '').toLowerCase();
      return content.contains(q);
    }).toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}

class LastWishesListController extends StateNotifier<LastWishesListState> {
  final Ref ref;

  LastWishesListController(this.ref)
    : super(const LastWishesListState(loading: true)) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final repo = ref.read(notesRepositoryProvider);
      final all = await repo.list(includeDeleted: false);

      final items =
          all
              .where((n) => n.kind == NoteKind.lastWishes && !n.isDeleted)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = state.copyWith(loading: false, items: items, clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setQuery(String value) {
    state = state.copyWith(query: value);
  }

  Future<void> delete(String noteId) async {
    try {
      final repo = ref.read(notesRepositoryProvider);
      final note = await repo.getById(noteId);
      if (note == null) return;

      final now = DateTime.now();

      await repo.upsert(
        note.copyWith(
          isDeleted: true,
          isSynced: false,
          updatedAt: now,
          version: note.version + 1,
        ),
      );

      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> restore(NoteBase backup) async {
    try {
      final repo = ref.read(notesRepositoryProvider);

      await repo.upsert(
        backup.copyWith(
          isDeleted: false,
          isSynced: false,
          updatedAt: DateTime.now(),
          version: backup.version + 1,
        ),
      );

      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
