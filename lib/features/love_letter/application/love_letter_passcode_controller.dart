import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final loveLetterPasscodeControllerProvider =
    AsyncNotifierProvider<
      LoveLetterPasscodeController,
      LoveLetterPasscodeState
    >(LoveLetterPasscodeController.new);

enum LovePassMode { none, passcode, qa }

class LoveLetterPasscodeState {
  final bool opening;
  final bool saving;
  final String? error;

  final String? noteId;
  final LovePassMode mode;

  // 用于回填 UI
  final String? passcode; // PASSCODE raw
  final String? qaPayload; // QA json: {"q":"..","a":".."}

  const LoveLetterPasscodeState({
    this.opening = true,
    this.saving = false,
    this.error,
    this.noteId,
    this.mode = LovePassMode.none,
    this.passcode,
    this.qaPayload,
  });

  LoveLetterPasscodeState copyWith({
    bool? opening,
    bool? saving,
    String? error,
    bool clearError = false,
    String? noteId,
    LovePassMode? mode,
    String? passcode,
    bool clearPasscode = false,
    String? qaPayload,
    bool clearQa = false,
  }) {
    return LoveLetterPasscodeState(
      opening: opening ?? this.opening,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      noteId: noteId ?? this.noteId,
      mode: mode ?? this.mode,
      passcode: clearPasscode ? null : (passcode ?? this.passcode),
      qaPayload: clearQa ? null : (qaPayload ?? this.qaPayload),
    );
  }
}

class LoveLetterPasscodeController
    extends AsyncNotifier<LoveLetterPasscodeState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  Timer? _debounce;

  // UI 输入缓存（用于防抖保存）
  String _pass1 = '';
  String _pass2 = '';
  String _q = '';
  String _a1 = '';
  String _a2 = '';

  @override
  Future<LoveLetterPasscodeState> build() async {
    ref.onDispose(() => _debounce?.cancel());
    return const LoveLetterPasscodeState(opening: true);
  }

  Future<void> open({required String noteId}) async {
    state = AsyncData(
      (state.value ?? const LoveLetterPasscodeState()).copyWith(
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
      final modeStr =
          (meta['passcodeMode'] as String?)?.toUpperCase() ?? 'NONE';

      LovePassMode mode;
      if (modeStr == 'PASSCODE') {
        mode = LovePassMode.passcode;
      } else if (modeStr == 'QA') {
        mode = LovePassMode.qa;
      } else {
        mode = LovePassMode.none;
      }

      final payload = (meta['passcodePayload'] as String?)?.trim();

      String? passcode;
      String? qaPayload;

      if (mode == LovePassMode.passcode) {
        passcode = payload;
        _pass1 = payload ?? '';
        _pass2 = payload ?? '';
      } else if (mode == LovePassMode.qa) {
        qaPayload = payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final m = jsonDecode(payload) as Map<String, dynamic>;
            _q = (m['q'] as String?) ?? '';
            _a1 = (m['a'] as String?) ?? '';
            _a2 = _a1;
          } catch (_) {}
        }
      }

      state = AsyncData(
        (state.value ?? const LoveLetterPasscodeState()).copyWith(
          opening: false,
          noteId: noteId,
          mode: mode,
          passcode: passcode,
          qaPayload: qaPayload,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? const LoveLetterPasscodeState()).copyWith(
          opening: false,
          error: e.toString(),
        ),
      );
    }
  }

  void setMode(LovePassMode mode) {
    final s = state.value;
    if (s == null) return;

    // 切换模式时，按你旧版逻辑：其它输入清空
    if (mode == LovePassMode.none) {
      _pass1 = '';
      _pass2 = '';
      _q = '';
      _a1 = '';
      _a2 = '';
      state = AsyncData(
        s.copyWith(
          mode: mode,
          clearPasscode: true,
          clearQa: true,
          clearError: true,
        ),
      );
    } else if (mode == LovePassMode.passcode) {
      _q = '';
      _a1 = '';
      _a2 = '';
      state = AsyncData(
        s.copyWith(mode: mode, clearQa: true, clearError: true),
      );
    } else {
      _pass1 = '';
      _pass2 = '';
      state = AsyncData(
        s.copyWith(mode: mode, clearPasscode: true, clearError: true),
      );
    }

    _scheduleSave();
  }

  void onUiChanged({
    required String pass1,
    required String pass2,
    required String q,
    required String a1,
    required String a2,
  }) {
    _pass1 = pass1;
    _pass2 = pass2;
    _q = q;
    _a1 = a1;
    _a2 = a2;
    _scheduleSave();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      saveNow();
    });
  }

  Future<void> saveNow() async {
    final s = state.value;
    if (s == null || s.noteId == null) return;
    if (s.saving) return;

    state = AsyncData(s.copyWith(saving: true, clearError: true));

    try {
      final note = await _repo.getById(s.noteId!);
      if (note == null) throw Exception('Note not found: ${s.noteId}');

      final meta = {...note.meta};

      // mode
      String modeStr;
      switch (s.mode) {
        case LovePassMode.none:
          modeStr = 'NONE';
          break;
        case LovePassMode.passcode:
          modeStr = 'PASSCODE';
          break;
        case LovePassMode.qa:
          modeStr = 'QA';
          break;
      }
      meta['passcodeMode'] = modeStr;

      // payload
      if (s.mode == LovePassMode.none) {
        meta.remove('passcodePayload');
        state = AsyncData(
          state.value!.copyWith(clearPasscode: true, clearQa: true),
        );
      } else if (s.mode == LovePassMode.passcode) {
        final p1 = _pass1.trim();
        final p2 = _pass2.trim();

        if (p1.isEmpty && p2.isEmpty) {
          meta.remove('passcodePayload');
          state = AsyncData(state.value!.copyWith(clearPasscode: true));
        } else if (p1.isEmpty || p1 != p2) {
          // 不合法：按你旧版策略，清掉 payload（避免保存半成品）
          meta.remove('passcodePayload');
          state = AsyncData(state.value!.copyWith(clearPasscode: true));
        } else {
          meta['passcodePayload'] = p1;
          state = AsyncData(
            state.value!.copyWith(passcode: p1, clearError: true),
          );
        }
      } else {
        final q = _q.trim();
        final a1 = _a1.trim();
        final a2 = _a2.trim();

        if (q.isEmpty && a1.isEmpty && a2.isEmpty) {
          meta.remove('passcodePayload');
          state = AsyncData(state.value!.copyWith(clearQa: true));
        } else if (q.isEmpty || a1.isEmpty || a1 != a2) {
          meta.remove('passcodePayload');
          state = AsyncData(state.value!.copyWith(clearQa: true));
        } else {
          final payload = jsonEncode({'q': q, 'a': a1});
          meta['passcodePayload'] = payload;
          state = AsyncData(
            state.value!.copyWith(qaPayload: payload, clearError: true),
          );
        }
      }

      await _repo.upsert(
        note.copyWith(
          meta: meta,
          updatedAt: DateTime.now(),
          isSynced: false,
          version: note.version + 1,
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
