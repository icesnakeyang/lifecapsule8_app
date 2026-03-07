import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';

final lastWishesDoneControllerProvider =
    AsyncNotifierProvider<LastWishesDoneController, LastWishesDoneState>(
      LastWishesDoneController.new,
    );

class LastWishesDoneState {
  final bool loading;
  final String? error;

  final String noteId;
  final NoteBase? note;

  /// 是否已启用（来自 note.meta['enabled']）
  final bool enabled;

  const LastWishesDoneState({
    this.loading = true,
    this.error,
    this.noteId = 'last_wishes',
    this.note,
    this.enabled = false,
  });

  LastWishesDoneState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    String? noteId,
    NoteBase? note,
    bool? enabled,
  }) {
    return LastWishesDoneState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      noteId: noteId ?? this.noteId,
      note: note ?? this.note,
      enabled: enabled ?? this.enabled,
    );
  }
}

class LastWishesDoneController extends AsyncNotifier<LastWishesDoneState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  @override
  Future<LastWishesDoneState> build() async {
    final base = const LastWishesDoneState(loading: true);
    return _load(base, noteId: base.noteId);
  }

  Future<void> setNoteId(String? noteId) async {
    final id = (noteId ?? '').trim().isEmpty ? 'last_wishes' : noteId!.trim();
    final cur = state.value ?? const LastWishesDoneState();
    state = AsyncData(
      cur.copyWith(noteId: id, loading: true, clearError: true),
    );
    final loaded = await _load(state.value ?? cur, noteId: id);
    state = AsyncData(loaded);
  }

  Future<void> refresh() async {
    final cur = state.value ?? const LastWishesDoneState();
    state = AsyncData(cur.copyWith(loading: true, clearError: true));
    final loaded = await _load(state.value ?? cur, noteId: cur.noteId);
    state = AsyncData(loaded);
  }

  Future<LastWishesDoneState> _load(
    LastWishesDoneState base, {
    required String noteId,
  }) async {
    try {
      final n = await _repo.getById(noteId);
      if (n == null || n.isDeleted == true) {
        return base.copyWith(
          loading: false,
          error: 'Draft not found.',
          enabled: false,
        );
      }

      final meta = (n.meta ?? const <String, dynamic>{});
      final enabled = (meta['enabled'] as bool?) ?? false;

      return base.copyWith(
        loading: false,
        note: n,
        enabled: enabled,
        clearError: true,
      );
    } catch (e) {
      return base.copyWith(loading: false, error: e.toString());
    }
  }

  /// 可选：给“Undo/Disable”用（如果你要）
  Future<void> disable() async {
    final s = state.value;
    if (s == null) return;
    final n = s.note;
    if (n == null) return;

    try {
      final meta = <String, dynamic>{...(n.meta ?? const {})};
      meta['enabled'] = false;

      final updated = n.copyWith(meta: meta, updatedAt: DateTime.now());

      await _repo.upsert(updated);
      state = AsyncData(
        (state.value ?? s).copyWith(
          note: updated,
          enabled: false,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData((state.value ?? s).copyWith(error: e.toString()));
    }
  }
}
