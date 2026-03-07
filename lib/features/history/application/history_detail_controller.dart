// lib/features/history/application/history_detail_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';

final historyDetailControllerProvider = FutureProvider.autoDispose
    .family<NoteBase?, String>((ref, noteId) async {
      final repo = ref.read(notesRepositoryProvider);

      final id = noteId.trim();
      if (id.isEmpty) return null;

      return repo.getById(id);
    });
