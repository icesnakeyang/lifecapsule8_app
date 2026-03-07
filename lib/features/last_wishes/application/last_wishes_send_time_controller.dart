import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final lastWishesSendTimeControllerProvider =
    AsyncNotifierProvider<
      LastWishesSendTimeController,
      LastWishesSendTimeState
    >(LastWishesSendTimeController.new);

enum LastWishesSendMode { afterYears, specificTime }

class LastWishesSendTimeState {
  final bool loading;
  final bool saving;
  final String? error;

  final NoteBase? note;
  final String noteId;

  final LastWishesSendMode mode;

  /// for afterYears
  final int? waitingYears;

  /// for specificTime
  final DateTime? sendAt;

  const LastWishesSendTimeState({
    this.loading = true,
    this.saving = false,
    this.error,
    this.note,
    this.noteId = 'last_wishes',
    this.mode = LastWishesSendMode.afterYears,
    this.waitingYears,
    this.sendAt,
  });

  LastWishesSendTimeState copyWith({
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
    NoteBase? note,
    String? noteId,
    LastWishesSendMode? mode,
    int? waitingYears,
    bool clearWaitingYears = false,
    DateTime? sendAt,
    bool clearSendAt = false,
  }) {
    return LastWishesSendTimeState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      note: note ?? this.note,
      noteId: noteId ?? this.noteId,
      mode: mode ?? this.mode,
      waitingYears: clearWaitingYears
          ? null
          : (waitingYears ?? this.waitingYears),
      sendAt: clearSendAt ? null : (sendAt ?? this.sendAt),
    );
  }
}

class LastWishesSendTimeController
    extends AsyncNotifier<LastWishesSendTimeState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  Timer? _debounce;

  @override
  Future<LastWishesSendTimeState> build() async {
    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
    });

    final base = const LastWishesSendTimeState(loading: true);
    return _load(base, noteId: base.noteId);
  }

  Future<void> setNoteId(String? noteId) async {
    final id = (noteId ?? '').trim().isEmpty ? 'last_wishes' : noteId!.trim();
    final cur = state.value ?? const LastWishesSendTimeState();
    state = AsyncData(
      cur.copyWith(noteId: id, loading: true, clearError: true),
    );
    final loaded = await _load(state.value ?? cur, noteId: id);
    state = AsyncData(loaded);
  }

  Future<void> refresh() async {
    final cur = state.value ?? const LastWishesSendTimeState();
    state = AsyncData(cur.copyWith(loading: true, clearError: true));
    final loaded = await _load(state.value ?? cur, noteId: cur.noteId);
    state = AsyncData(loaded);
  }

  Future<LastWishesSendTimeState> _load(
    LastWishesSendTimeState base, {
    required String noteId,
  }) async {
    try {
      final n = await _repo.getById(noteId);
      if (n == null || n.isDeleted == true) {
        return base.copyWith(
          loading: false,
          error: 'Draft not found. Please write it first.',
        );
      }

      final meta = (n.meta ?? const <String, dynamic>{});

      final modeStr = (meta['sendMode'] as String?)?.trim().toLowerCase();
      final mode = modeStr == 'specific_time'
          ? LastWishesSendMode.specificTime
          : LastWishesSendMode.afterYears;

      final years = (meta['waitingYears'] as num?)?.toInt();

      DateTime? sendAt;
      final sendAtIso = (meta['sendAt'] as String?)?.trim();
      if (sendAtIso != null && sendAtIso.isNotEmpty) {
        sendAt = DateTime.tryParse(sendAtIso);
      }

      return base.copyWith(
        loading: false,
        note: n,
        noteId: noteId,
        mode: mode,
        waitingYears: years,
        sendAt: sendAt,
        clearError: true,
      );
    } catch (e) {
      return base.copyWith(loading: false, error: e.toString());
    }
  }

  // ----------------- setters -----------------

  /// ✅ 让 UI 可以 await（避免你之前的 void 报错）
  Future<void> setMode(LastWishesSendMode mode) async {
    final s = state.value;
    if (s == null) return;

    // 切换模式时：保留对方字段也行，但为了更清晰，这里清掉冲突字段
    if (mode == LastWishesSendMode.afterYears) {
      state = AsyncData(
        s.copyWith(mode: mode, clearSendAt: true, clearError: true),
      );
    } else {
      state = AsyncData(
        s.copyWith(mode: mode, clearWaitingYears: true, clearError: true),
      );
    }

    _scheduleSave();
  }

  Future<void> setWaitingYears(int years) async {
    final s = state.value;
    if (s == null) return;

    state = AsyncData(
      s.copyWith(
        waitingYears: years,
        mode: LastWishesSendMode.afterYears,
        clearSendAt: true,
        clearError: true,
      ),
    );
    _scheduleSave();
  }

  Future<void> setSendAt(DateTime dt) async {
    final s = state.value;
    if (s == null) return;

    state = AsyncData(
      s.copyWith(
        sendAt: dt,
        mode: LastWishesSendMode.specificTime,
        clearWaitingYears: true,
        clearError: true,
      ),
    );
    _scheduleSave();
  }

  // ----------------- persistence -----------------

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await saveNow();
    });
  }

  /// ✅ 你之前报 “saveNow 不存在”，这里补上
  Future<void> saveNow() async {
    final s = state.value;
    if (s == null) return;
    final n = s.note;
    if (n == null) return;
    if (s.saving) return;

    state = AsyncData(s.copyWith(saving: true, clearError: true));

    try {
      final meta = <String, dynamic>{
        ...(n.meta ?? const <String, dynamic>{}),
        'sendMode': s.mode == LastWishesSendMode.specificTime
            ? 'specific_time'
            : 'after_years',
        'waitingYears': s.mode == LastWishesSendMode.afterYears
            ? s.waitingYears
            : null,
        'sendAt': s.mode == LastWishesSendMode.specificTime
            ? s.sendAt?.toIso8601String()
            : null,
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
          saving: false,
          note: updated,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? s).copyWith(saving: false, error: e.toString()),
      );
    }
  }

  // ----------------- validation helpers -----------------

  bool get canGoNext {
    final s = state.value;
    if (s == null) return false;
    if (s.loading || s.saving) return false;

    if (s.mode == LastWishesSendMode.afterYears) {
      return s.waitingYears != null &&
          const [1, 5, 10, 20].contains(s.waitingYears);
    }

    final dt = s.sendAt;
    if (dt == null) return false;
    return dt.isAfter(DateTime.now().add(const Duration(minutes: 1)));
  }
}
