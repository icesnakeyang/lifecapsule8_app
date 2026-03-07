import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final lastWishesListControllerProvider =
    AsyncNotifierProvider<LastWishesListController, LastWishesListState>(
      LastWishesListController.new,
    );

class LastWishesListState {
  final List<LastWishesListItem> items;

  const LastWishesListState({required this.items});

  LastWishesListState copyWith({List<LastWishesListItem>? items}) {
    return LastWishesListState(items: items ?? this.items);
  }
}

class LastWishesListItem {
  final String id;
  final String? title;
  final String? preview;
  final bool enabled;
  final int? waitingYears;

  const LastWishesListItem({
    required this.id,
    this.title,
    this.preview,
    required this.enabled,
    this.waitingYears,
  });
}

class LastWishesListController extends AsyncNotifier<LastWishesListState> {
  @override
  Future<LastWishesListState> build() async {
    return _load();
  }

  Future<LastWishesListState> _load() async {
    final repo = ref.read(notesRepositoryProvider);
    final notes = await repo.list(includeDeleted: false);

    final filtered = notes.where((n) {
      return n.kind == NoteKind.lastWishes;
    }).toList();

    final items = filtered.map((n) {
      final enabled = (n.meta['enabled'] as bool?) ?? false;
      final waitingYears = n.meta['waitingYears'] as int?;
      return LastWishesListItem(
        id: n.id,
        title: n.meta['title'] as String?,
        preview: n.meta['preview'] as String?,
        enabled: enabled,
        waitingYears: waitingYears,
      );
    }).toList();
    return LastWishesListState(items: items);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await _load();
    });
  }
}
