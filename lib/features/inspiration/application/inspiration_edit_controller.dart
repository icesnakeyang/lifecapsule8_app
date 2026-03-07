// lib/features/inspiration/application/inspiration_edit_controller.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final inspirationEditControllerProvider =
    AsyncNotifierProvider<InspirationEditController, InspirationEditState>(
      InspirationEditController.new,
    );

class InspirationEditState {
  final bool loading;
  final bool saving;
  final bool persisted;
  final String? error;
  final NoteBase? note;

  const InspirationEditState({
    this.loading = true,
    this.saving = false,
    this.persisted = false,
    this.error,
    this.note,
  });

  InspirationEditState copyWith({
    bool? loading,
    bool? saving,
    bool? persisted,
    String? error,
    bool clearError = false,
    NoteBase? note,
  }) {
    return InspirationEditState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      persisted: persisted ?? this.persisted,
      error: clearError ? null : (error ?? this.error),
      note: note ?? this.note,
    );
  }
}

class InspirationEditController extends AsyncNotifier<InspirationEditState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  /// Inspiration 是“单页草稿板”，用固定 noteId 即可（每用户一份由 repo/userId 区分）
  static const String _noteId = 'inspiration';

  Timer? _debounce;

  @override
  Future<InspirationEditState> build() async {
    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
    });

    final base = const InspirationEditState(loading: true);

    try {
      final existing = await _repo.getById(_noteId);

      if (existing != null && existing.isDeleted != true) {
        return base.copyWith(
          loading: false,
          persisted: true,
          note: existing,
          clearError: true,
        );
      }

      // ⚠️ NoteBase 可能 required userId：这里不直接 new NoteBase，避免你又遇到 userId 必填报错
      // 先用一个“内存占位草稿”，真正落库时由 saveNow() 用 repo.upsert 处理（你 repo 实现里一般会补齐 userId）
      final now = DateTime.now();
      final draft =
          (existing ??
                  NoteBase(
                    id: _noteId,
                    userId: 'userId',
                    kind: NoteKind.inspiration,
                    content: '',
                    meta: const {},
                    createdAt: now,
                    updatedAt: now,
                    isDeleted: false,
                    // 如果你 NoteBase 构造函数 required userId：
                    // 这里你必须填一个（比如 'local'），或者你把 NoteBase 改成 userId 可空 + repo 落库时补齐
                    // userId: 'local',
                  ))
              .copyWith(
                kind: NoteKind.inspiration,
                content: '',
                meta: const {},
                createdAt: now,
                updatedAt: now,
                isDeleted: false,
              );

      return base.copyWith(
        loading: false,
        persisted: false,
        note: draft,
        clearError: true,
      );
    } catch (e) {
      return base.copyWith(loading: false, error: e.toString());
    }
  }

  // ───────────────────── UI actions ─────────────────────

  void updateContent(String text, {int? cursorOffset, double? scrollTop}) {
    final s = state.value;
    if (s == null) return;
    final n = s.note;
    if (n == null) return;

    final now = DateTime.now();
    final meta = Map<String, dynamic>.from(n.meta ?? const {});
    if (cursorOffset != null) meta['cursorOffset'] = cursorOffset;
    if (scrollTop != null) meta['scrollTop'] = scrollTop;

    final updated = n.copyWith(
      content: text,
      meta: meta,
      updatedAt: now,
      isDeleted: false,
    );

    state = AsyncData(s.copyWith(note: updated, clearError: true));
    _scheduleSave();
  }

  /// 只更新 UI 状态（不改内容），用于滚动节流保存
  void updateUiState({int? cursorOffset, double? scrollTop}) {
    final s = state.value;
    if (s == null) return;
    final n = s.note;
    if (n == null) return;

    final meta = Map<String, dynamic>.from(n.meta ?? const {});
    if (cursorOffset != null) meta['cursorOffset'] = cursorOffset;
    if (scrollTop != null) meta['scrollTop'] = scrollTop;

    final updated = n.copyWith(meta: meta, updatedAt: DateTime.now());
    state = AsyncData(s.copyWith(note: updated, clearError: true));
    _scheduleSave();
  }

  Future<void> persistNow() async => saveNow();

  Future<void> saveNow() async {
    final s = state.value;
    if (s == null) return;
    final n = s.note;
    if (n == null) return;
    if (s.saving) return;

    final content = (n.content ?? '').trim();

    state = AsyncData(s.copyWith(saving: true, clearError: true));

    try {
      if (content.isEmpty) {
        if (s.persisted) {
          await _repo.markDeleted(n.id);
          state = AsyncData(s.copyWith(saving: false, persisted: false));
        } else {
          state = AsyncData(s.copyWith(saving: false));
        }
        return;
      }

      // ✅ 统一写入 notes_box
      await _repo.upsert(
        n.copyWith(
          kind: NoteKind.inspiration,
          content: content,
          isDeleted: false,
          updatedAt: DateTime.now(),
        ),
      );

      state = AsyncData(
        (state.value ?? s).copyWith(
          saving: false,
          persisted: true,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? s).copyWith(saving: false, error: e.toString()),
      );
    }
  }

  // ───────────────────── internal ─────────────────────

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      await saveNow();
    });
  }
}
