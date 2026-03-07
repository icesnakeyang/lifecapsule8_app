import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final loveLetterSendTimeControllerProvider =
    AsyncNotifierProvider<
      LoveLetterSendTimeController,
      LoveLetterSendTimeState
    >(LoveLetterSendTimeController.new);

enum LoveSendMode { specificTime, primaryCountdown, instantly, later }

class LoveLetterSendTimeState {
  final bool opening;
  final bool saving;
  final String? error;

  final String? noteId;
  final NoteBase? note;

  final LoveSendMode mode;
  final DateTime? sendAtLocal;

  const LoveLetterSendTimeState({
    this.opening = true,
    this.saving = false,
    this.error,
    this.noteId,
    this.note,
    this.mode = LoveSendMode.specificTime,
    this.sendAtLocal,
  });

  bool get canNext {
    if (mode == LoveSendMode.specificTime) return sendAtLocal != null;
    return true;
  }

  LoveLetterSendTimeState copyWith({
    bool? opening,
    bool? saving,
    String? error,
    bool clearError = false,
    String? noteId,
    NoteBase? note,
    LoveSendMode? mode,
    DateTime? sendAtLocal,
    bool clearSendAt = false,
  }) {
    return LoveLetterSendTimeState(
      opening: opening ?? this.opening,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      noteId: noteId ?? this.noteId,
      note: note ?? this.note,
      mode: mode ?? this.mode,
      sendAtLocal: clearSendAt ? null : (sendAtLocal ?? this.sendAtLocal),
    );
  }
}

class LoveLetterSendTimeController
    extends AsyncNotifier<LoveLetterSendTimeState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  Timer? _debounce;

  @override
  Future<LoveLetterSendTimeState> build() async {
    ref.onDispose(() => _debounce?.cancel());
    return const LoveLetterSendTimeState(opening: true);
  }

  Future<void> open({required String noteId}) async {
    state = AsyncData(
      (state.value ?? const LoveLetterSendTimeState()).copyWith(
        opening: true,
        clearError: true,
      ),
    );

    try {
      final note = await _repo.getById(noteId);
      if (note == null || note.kind != NoteKind.loveLetter) {
        throw Exception('Love letter note not found: $noteId');
      }

      final meta = note.meta;
      final modeStr = (meta['sendMode'] as String?)?.toUpperCase();
      final sendAtIso = meta['sendAtIso'] as String?;

      LoveSendMode mode;
      if (modeStr == 'PRIMARY_COUNTDOWN') {
        mode = LoveSendMode.primaryCountdown;
      } else if (modeStr == 'INSTANTLY') {
        mode = LoveSendMode.instantly;
      } else if (modeStr == 'LATER') {
        mode = LoveSendMode.later;
      } else {
        mode = LoveSendMode.specificTime;
      }

      DateTime? sendAt;
      if (sendAtIso != null && sendAtIso.trim().isNotEmpty) {
        sendAt = DateTime.tryParse(sendAtIso);
      }

      state = AsyncData(
        (state.value ?? const LoveLetterSendTimeState()).copyWith(
          opening: false,
          noteId: noteId,
          note: note,
          mode: mode,
          sendAtLocal: sendAt,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? const LoveLetterSendTimeState()).copyWith(
          opening: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> setMode(LoveSendMode mode) async {
    final s = state.value;
    if (s == null) return;

    // 如果切换到非 specificTime，可以保留 sendAt（也可以选择清掉）
    state = AsyncData(s.copyWith(mode: mode, clearError: true));
    await _saveNow();
  }

  Future<void> setSpecificTime(DateTime sendAtLocal) async {
    final s = state.value;
    if (s == null) return;

    state = AsyncData(
      s.copyWith(
        mode: LoveSendMode.specificTime,
        sendAtLocal: sendAtLocal,
        clearError: true,
      ),
    );
    _scheduleSave();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _saveNow();
    });
  }

  Future<void> _saveNow() async {
    final s = state.value;
    if (s == null) return;

    state = AsyncData(s.copyWith(clearError: true));
  }

  Future<void> flush() async {
    _debounce?.cancel();
    await _saveNow();
  }

  String _modeToStr(LoveSendMode m) {
    switch (m) {
      case LoveSendMode.specificTime:
        return 'SPECIFIC_TIME';
      case LoveSendMode.primaryCountdown:
        return 'PRIMARY_COUNTDOWN';
      case LoveSendMode.instantly:
        return 'INSTANTLY';
      case LoveSendMode.later:
        return 'LATER';
    }
  }

  Future<void> save() async {
    final s = state.value;
    if (s == null || s.noteId == null) return;
    if (s.saving) return;

    state = AsyncData(s.copyWith(saving: true, clearError: true));

    try {
      final cur = await _repo.getById(s.noteId!);
      if (cur == null) throw Exception('Note not found: ${s.noteId}');

      final meta = {...cur.meta};

      meta['sendMode'] = _modeToStr(s.mode);

      if (s.mode == LoveSendMode.specificTime) {
        final t = s.sendAtLocal;
        if (t != null) {
          // 用 ISO8601（本地）存即可；如你需要带 offset，可替换成你 dt_localized 的工具
          meta['sendAtIso'] = t.toIso8601String();
        } else {
          meta.remove('sendAtIso');
        }
      } else {
        // 非 specificTime：建议清掉 sendAtIso，避免产生误解
        meta.remove('sendAtIso');
      }

      await _repo.upsert(
        cur.copyWith(
          meta: meta,
          updatedAt: DateTime.now(),
          isSynced: false,
          version: cur.version + 1,
        ),
      );

      state = AsyncData(
        (state.value ?? s).copyWith(saving: false, clearError: true),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? s).copyWith(saving: false, error: e.toString()),
      );
    }
  }
}
