// lib/features/future_letter/presentation/future_letter_list_page.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';
import 'package:uuid/uuid.dart';

final futureLetterListControllerProvider =
    NotifierProvider<FutureLetterListController, FutureLetterListState>(
      FutureLetterListController.new,
    );

class FutureLetterListState {
  final bool loading;
  final String? error;
  final List<NoteBase> items;
  final String query;

  const FutureLetterListState({
    this.loading = false,
    this.error,
    this.items = const [],
    this.query = '',
  });

  FutureLetterListState copyWith({
    bool? loading,
    String? error,
    List<NoteBase>? items,
    String? query,
  }) {
    return FutureLetterListState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      query: query ?? this.query,
    );
  }

  List<NoteBase> get filtered {
    if (query.trim().isEmpty) return items;
    final q = query.toLowerCase();

    return items.where((n) {
      final title = (n.meta['title'] ?? '').toString().toLowerCase();
      final content = (n.content ?? '').toLowerCase();
      return title.contains(q) || content.contains(q);
    }).toList();
  }
}

class FutureLetterListController extends Notifier<FutureLetterListState> {
  @override
  FutureLetterListState build() {
    final init = const FutureLetterListState(loading: true);
    Future.microtask(_load);      
    return init;
  }

  Future<void> _load() async {
    final currentQuery = state.query;
    state = FutureLetterListState(
      loading: true,
      items: state.items,
      query: currentQuery,
    );

    try {
      final repo = ref.read(notesRepositoryProvider);
      final all = await repo.list(includeDeleted: false);

      final list = all.where((n) => n.kind == NoteKind.futureLetter).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(loading: false, error: null, items: list);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  Future<String> createDraft() async {
    final box = ref.read(notesBoxProvider);

    final id = const Uuid().v4();
    final now = DateTime.now();

    // ⚠️ userId 你项目里通常来自 profile/session；这里先放空或 'local'
    // 你如果有 auth/user provider，就换成实际 userId
    final note = NoteBase(
      id: id,
      userId: 'local',
      kind: NoteKind.futureLetter,
      createdAt: now,
      updatedAt: now,
      content: '',
      enc: null,
      serverNoteId: null,
      isSynced: false,
      isDeleted: false,
      version: 1,
      meta: const {'title': '', 'subtitle': ''},
    );

    // ✅ 关键：把 NoteBase 序列化成 String 存入 Hive
    // 前提：你 NoteBase 有 toJson()；如果没有，看下面“没有 toJson() 怎么办”
    await box.put(id, jsonEncode(note.toJson()));

    await _load();
    return id;
  }
}
