import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final lastWishesPreviewControllerProvider =
    AsyncNotifierProvider<LastWishesPreviewController, LastWishesPreviewState>(
      LastWishesPreviewController.new,
    );

class LastWishesPreviewState {
  final bool loading;
  final bool submitting;
  final String? error;

  final NoteBase? note;

  // derived fields
  final String content;
  final String recipientEmail;
  final int? waitingYears;
  final String messageNote;
  final bool enabled;

  const LastWishesPreviewState({
    this.loading = true,
    this.submitting = false,
    this.error,
    this.note,
    this.content = '',
    this.recipientEmail = '',
    this.waitingYears,
    this.messageNote = '',
    this.enabled = false,
  });

  LastWishesPreviewState copyWith({
    bool? loading,
    bool? submitting,
    String? error,
    bool clearError = false,
    NoteBase? note,
    String? content,
    String? recipientEmail,
    int? waitingYears,
    bool clearWaitingYears = false,
    String? messageNote,
    bool? enabled,
  }) {
    return LastWishesPreviewState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
      note: note ?? this.note,
      content: content ?? this.content,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      waitingYears: clearWaitingYears
          ? null
          : (waitingYears ?? this.waitingYears),
      messageNote: messageNote ?? this.messageNote,
      enabled: enabled ?? this.enabled,
    );
  }
}

class LastWishesPreviewController
    extends AsyncNotifier<LastWishesPreviewState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  static const String _defaultNoteId = 'last_wishes';
  String _noteId = _defaultNoteId;

  /// Page 进来后可调用 setNoteId(noteId) 再 refresh()
  void setNoteId(String? noteId) {
    final v = (noteId ?? '').trim();
    _noteId = v.isEmpty ? _defaultNoteId : v;
  }

  @override
  Future<LastWishesPreviewState> build() async {
    final base = const LastWishesPreviewState(loading: true);
    return _load(base);
  }

  Future<void> refresh() async {
    final cur = state.value ?? const LastWishesPreviewState();
    state = AsyncData(cur.copyWith(loading: true, clearError: true));
    final loaded = await _load(state.value ?? cur);
    state = AsyncData(loaded);
  }

  Future<LastWishesPreviewState> _load(LastWishesPreviewState base) async {
    try {
      final n = await _repo.getById(_noteId);

      if (n == null || n.isDeleted == true) {
        return base.copyWith(
          loading: false,
          error: 'Draft not found. Please write it first.',
        );
      }

      final meta = (n.meta ?? const <String, dynamic>{});
      final email = (meta['recipientEmail'] as String?)?.trim() ?? '';
      final years = (meta['waitingYears'] as num?)?.toInt();
      final noteMsg = (meta['messageNote'] as String?) ?? '';
      final enabled = (meta['enabled'] as bool?) ?? false;

      final content = (n.content ?? '').trim();

      return base.copyWith(
        loading: false,
        note: n,
        content: content,
        recipientEmail: email,
        waitingYears: years,
        messageNote: noteMsg,
        enabled: enabled,
        clearError: true,
      );
    } catch (e) {
      return base.copyWith(loading: false, error: e.toString());
    }
  }

  // ----------------- validation -----------------

  bool get canConfirm {
    final s = state.value;
    if (s == null) return false;
    if (s.submitting) return false;
    if (s.enabled) return false;

    if (s.content.trim().isEmpty) return false;

    final email = s.recipientEmail.trim();
    if (!_isValidEmail(email)) return false;

    final years = s.waitingYears;
    if (years == null || !const [1, 5, 10, 20].contains(years)) return false;

    return true;
  }

  bool _isValidEmail(String v) {
    final e = v.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  // ----------------- confirm -----------------

  /// 预览页点击 Confirm：把 enabled=true 写回 note.meta
  /// ⚠️ send_task 的创建逻辑你后面迁移 send_task 模块时再接上（按你的 MVC 规范再做一套）
  Future<bool> confirmEnable() async {
    final s = state.value;
    if (s == null) return false;
    if (s.enabled) {
      state = AsyncData(
        s.copyWith(error: 'Already enabled.', clearError: false),
      );
      return false;
    }
    final n = s.note;
    if (n == null) return false;

    if (!canConfirm) {
      state = AsyncData(
        s.copyWith(
          error: 'Please complete content / recipient / waiting period.',
        ),
      );
      return false;
    }

    state = AsyncData(s.copyWith(submitting: true, clearError: true));

    try {
      final meta = <String, dynamic>{
        ...(n.meta ?? const <String, dynamic>{}),
        'enabled': true,
        // 再兜底写回当前字段（保证一致）
        'recipientEmail': s.recipientEmail.trim(),
        'waitingYears': s.waitingYears,
        'messageNote': s.messageNote.trim().isEmpty
            ? null
            : s.messageNote.trim(),
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      };

      final updated = n.copyWith(
        kind: NoteKind.lastWishes,
        meta: meta,
        updatedAt: DateTime.now(),
        isDeleted: false,
      );

      await _repo.upsert(updated);

      state = AsyncData(
        (state.value ?? s).copyWith(
          submitting: false,
          note: updated,
          enabled: true,
          clearError: true,
        ),
      );
      return true;
    } catch (e) {
      state = AsyncData(
        (state.value ?? s).copyWith(submitting: false, error: e.toString()),
      );
      return false;
    }
  }
}
