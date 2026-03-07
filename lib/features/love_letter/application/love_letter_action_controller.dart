import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final loveLetterActionControllerProvider =
    AsyncNotifierProvider<LoveLetterActionController, LoveLetterActionState>(
      LoveLetterActionController.new,
    );

class LoveLetterActionState {
  final bool isLoading;
  final NoteBase? note;
  final String? error;

  const LoveLetterActionState({this.isLoading = true, this.note, this.error});

  LoveLetterActionState copyWith({
    bool? isLoading,
    NoteBase? note,
    String? error,
    bool clearError = false,
  }) {
    return LoveLetterActionState(
      isLoading: isLoading ?? this.isLoading,
      note: note ?? this.note,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LoveLetterActionController extends AsyncNotifier<LoveLetterActionState> {
  String? _currentNoteId;

  @override
  Future<LoveLetterActionState> build() async {
    return const LoveLetterActionState(isLoading: true);
  }

  /// 页面打开时调用，传入 noteId 来加载数据
  Future<void> loadNote(String? noteId) async {
    if (noteId == null) {
      state = const AsyncData(
        LoveLetterActionState(isLoading: false, error: 'No note ID provided'),
      );
      return;
    }

    _currentNoteId = noteId;
    state = const AsyncLoading();

    try {
      final repo = ref.read(notesRepositoryProvider);
      final note = await repo.getById(noteId);

      if (note == null || note.kind != NoteKind.loveLetter) {
        state = const AsyncData(
          LoveLetterActionState(
            isLoading: false,
            error: 'Letter not found or invalid type',
          ),
        );
        return;
      }

      state = AsyncData(LoveLetterActionState(isLoading: false, note: note));
    } catch (e) {
      state = AsyncData(
        LoveLetterActionState(isLoading: false, error: e.toString()),
      );
    }
  }

  /// 可选：刷新当前加载的 note
  Future<void> refresh() async {
    if (_currentNoteId == null) return;
    await loadNote(_currentNoteId);
  }
}
