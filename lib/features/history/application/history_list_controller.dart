// lib/features/history/application/history_list_controller.dart
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/user/application/user_store.dart';

final historyListControllerProvider =
    AsyncNotifierProvider.autoDispose<HistoryListController, List<NoteBase>>(
      HistoryListController.new,
    );

class HistoryListController extends AsyncNotifier<List<NoteBase>> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  String get _userId => ref.read(userProvider).currentUser?.userId ?? '';

  @override
  Future<List<NoteBase>> build() async {
    return _loadRandom20();
  }

  Future<void> refreshRandom() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadRandom20);
  }

  Future<List<NoteBase>> _loadRandom20() async {
    final userId = _userId;
    if (userId.isEmpty) return [];

    // ✅ 你项目里 NotesRepository 的真实方法名如果不同，把这里改成你已有的方法
    // 例如：repo.list(userId: userId, includeDeleted: false)
    final all = await _repo.list(includeDeleted: false);
    final mine = all.where((n) => n.userId == userId).toList();
    if (mine.isEmpty) return [];

    mine.shuffle(Random());
    return mine.take(20).toList();
  }
}
