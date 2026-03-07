import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/providers/app_providers.dart';
import 'package:lifecapsule8_app/core/constants/prefs_keys.dart';

import '../data/notes_repository.dart';
import '../data/cloud_notes_service.dart';

class NotesSyncService {
  final Ref ref;
  final NotesRepository repository;
  final CloudNotesService cloud;

  NotesSyncService({
    required this.repository,
    required this.cloud,
    required this.ref,
  });

  bool _syncing = false;

  Future<void> sync() async {
    final prefs = ref.read(sharedPrefsProvider);
    final stage = prefs.getInt(PrefsKeys.syncState) ?? 0;
    if (stage < 2) return;

    if (_syncing) return;
    _syncing = true;

    try {
      final pending = await repository.list(includeDeleted: true);

      final unsynced = pending.where((n) {
        final noServerId =
            (n.serverNoteId == null) || (n.serverNoteId!.isEmpty);
        return !n.isSynced || noServerId;
      }).toList();

      for (final note in unsynced) {
        final enc = note.enc;
        if (enc == null || enc.isEmpty) {
          // print('[NotesSync] skip: enc empty id=${note.id}');
          continue;
        }
        try {
          final r = await cloud.upload(note);

          if (r.serverNoteId.isEmpty) {
            throw StateError('upload ok but serverNoteId empty');
          }

          await repository.markSynced(
            id: note.id,
            serverNoteId: r.serverNoteId,
            updatedAt: r.updatedAt,
            version: r.version,
          );
        } catch (e, st) {
          // 关键：失败就不要 markSynced，留到下次重试
          print('[NotesSync] upload failed id=${note.id}: $e\n$st');
        }
      }
    } finally {
      _syncing = false;
    }
  }
}
