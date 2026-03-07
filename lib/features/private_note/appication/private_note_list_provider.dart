import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final privateNoteListProvider = StreamProvider<List<NoteBase>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.watchList(kind: NoteKind.privateNote, includeDeleted: false);
});
