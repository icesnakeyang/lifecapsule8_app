import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

abstract class NotesRepository {
  Future<NoteBase?> getById(String id);
  Future<List<NoteBase>> list({NoteKind? kind, bool includeDeleted = false});
  Stream<List<NoteBase>> watchList({
    NoteKind? kind,
    bool includeDeleted = false,
  });
  Future<void> upsert(NoteBase note);
  Future<void> markDeleted(String id);

  Future<void> changeKind({required String id, required NoteKind kind});

  Future<void> markSynced({
    required String id,
    required String serverNoteId,
    required DateTime updatedAt,
    required int version,
  });

  Future<void> delete(String id);
}
