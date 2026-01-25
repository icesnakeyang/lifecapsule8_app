import 'package:lifecapsule8_app/provider/note/local_note.dart';

class NoteState {
  final bool loading;
  final String? error;
  final LocalNote? currentNote;
  final List<LocalNote> notes;

  const NoteState({
    this.loading = false,
    this.error,
    this.currentNote,
    this.notes = const [],
  });

  factory NoteState.initial() {
    return const NoteState(
      loading: false,
      error: null,
      currentNote: null,
      notes: [],
    );
  }

  NoteState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    LocalNote? currentNote,
    bool clearCurrentNote = false,
    List<LocalNote>? notes,
  }) {
    return NoteState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      currentNote: clearCurrentNote ? null : (currentNote ?? this.currentNote),
      notes: notes ?? this.notes,
    );
  }
}
