import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:lifecapsule8_app/core/constants/hive_boxes.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_sync_service.dart';
import 'package:lifecapsule8_app/features/notes_base/data/cloud_notes_service.dart';
import 'package:lifecapsule8_app/features/notes_base/data/hive_notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';

/// Hive Box
final notesBoxProvider = Provider<Box<String>>((ref) {
  return Hive.box<String>(HiveBoxes.notes);
});

/// Repository
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return HiveNotesRepository(ref.watch(notesBoxProvider));
});

/// Cloud service
final cloudNotesServiceProvider = Provider<CloudNotesService>((ref) {
  return CloudNotesService();
});

/// Sync service
final notesSyncServiceProvider = Provider<NotesSyncService>((ref) {
  final repo = ref.read(notesRepositoryProvider);
  final cloud = ref.read(cloudNotesServiceProvider);

  return NotesSyncService(ref: ref, repository: repo, cloud: cloud);
});

final notesCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(notesRepositoryProvider);
  final list = await repo.list(includeDeleted: false);
  return list.length;
});
