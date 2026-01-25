// lib/provider/last_wishes/last_wishes_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/last_wishes/last_wishes_repo.dart';
import 'package:lifecapsule8_app/provider/note/note_provider.dart';
import 'package:lifecapsule8_app/provider/send_task/send_task_notifier.dart';
import 'last_wishes_state.dart';

final lastWishesProvider =
    NotifierProvider<LastWishesNotifier, LastWishesState>(() {
      return LastWishesNotifier();
    });

class LastWishesNotifier extends Notifier<LastWishesState> {
  late final _repo = LastWishesRepo();

  Timer? _debounce;
  bool _syncing = false;

  @override
  LastWishesState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
    });
    return _repo.loadDraftIntoState() ?? LastWishesState.initial();
  }

  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        await syncToBackend();
      } catch (_) {
        // swallow: 后台自动同步失败不打断用户操作
      }
    });
  }

  Future<void> syncToBackend() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final meta = <String, dynamic>{
        'kind': 'LAST_WISHES',
        'destination': state.destination.name,
        'recipientEmail': state.recipientEmail,
        'waitingYears': state.waitingYears,
        'enabled': state.enabled,
        'messageNote': state.messageNote,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      };

      await ref
          .read(noteProvider.notifier)
          .upsertBusinessNote(
            noteId: state.noteId, // ✅ 用 state.noteId
            noteType: 'LAST_WISHES',
            plainText: state.content,
            meta: meta,
          );
    } finally {
      _syncing = false;
    }
  }

  // ────────────────────── Flow Step ──────────────────────

  Future<void> goTo(LastWishesStep step) async {
    state = state.copyWith(step: step, clearError: true);
    await _persistLocal();
  }

  Future<void> next() async {
    switch (state.step) {
      case LastWishesStep.intro:
        await goTo(LastWishesStep.write);
        break;
      case LastWishesStep.write:
        await goTo(LastWishesStep.destination);
        break;
      case LastWishesStep.destination:
        // 当前版本 world 未开放，强制走 person
        if (state.destination != LastWishesDestination.person) {
          state = state.copyWith(destination: LastWishesDestination.person);
        }
        await goTo(LastWishesStep.recipient);
        break;
      case LastWishesStep.recipient:
        await goTo(LastWishesStep.preview);
        break;
      case LastWishesStep.preview:
        // preview 的 next 通常是 confirmSubmit()
        break;
      case LastWishesStep.done:
        break;
    }
  }

  Future<void> back() async {
    switch (state.step) {
      case LastWishesStep.intro:
        break;
      case LastWishesStep.write:
        await goTo(LastWishesStep.intro);
        break;
      case LastWishesStep.destination:
        await goTo(LastWishesStep.write);
        break;
      case LastWishesStep.recipient:
        await goTo(LastWishesStep.destination);
        break;
      case LastWishesStep.preview:
        await goTo(LastWishesStep.recipient);
        break;
      case LastWishesStep.done:
        // done 返回 preview 或 recipient 取决于你的 UX，这里回 preview
        await goTo(LastWishesStep.preview);
        break;
    }
  }

  // ────────────────────── Draft Fields ──────────────────────

  void setContent(String text) {
    state = state.copyWith(content: text, clearError: true);
    _persistLocal(scheduleSync: true);
  }

  /// 当前版本：只允许 person（world 灰色）
  void setDestination(LastWishesDestination dest) {
    if (dest == LastWishesDestination.world) {
      state = state.copyWith(
        destination: LastWishesDestination.person,
        error: 'Public release is coming later.',
      );
      _persistLocal(scheduleSync: true);
      return;
    }
    state = state.copyWith(destination: dest, clearError: true);
    _persistLocal(scheduleSync: true);
  }

  void setRecipientEmail(String email) {
    final e = email.trim();
    state = state.copyWith(
      recipientEmail: e.isEmpty ? null : e,
      clearError: true,
    );
    _persistLocal(scheduleSync: true);
  }

  void setWaitingYears(int years) {
    state = state.copyWith(waitingYears: years, clearError: true);
    _persistLocal(scheduleSync: true);
  }

  // ────────────────────── Validation ──────────────────────

  bool get canContinueFromWrite => state.content.trim().isNotEmpty;

  bool get canContinueFromRecipient {
    final email = state.recipientEmail?.trim() ?? '';
    final years = state.waitingYears;

    final okEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    final okYears = years != null && const [1, 5, 10, 20].contains(years);
    return okEmail && okYears;
  }

  // ────────────────────── Submit ──────────────────────

  /// 预览页点击 Confirm 后调用
  Future<bool> confirmAndEnable() async {
    // 最小校验
    if (state.content.trim().isEmpty) {
      state = state.copyWith(error: 'Content is empty.');
      await _persistLocal();
      return false;
    }

    if (!canContinueFromRecipient) {
      state = state.copyWith(
        error: 'Recipient email or waiting period is invalid.',
      );
      await _persistLocal();
      return false;
    }

    state = state.copyWith(submitting: true, clearError: true);
    await _persistLocal();

    try {
      state = state.copyWith(enabled: true);
      await _persistLocal();

      await syncToBackend();

      final scheduleAt = _calcScheduleAt(state.waitingYears!);

      await ref
          .read(sendTaskProvider.notifier)
          .upsertLastWishesTask(
            noteId: state.noteId,
            recipientEmail: state.recipientEmail!,
            scheduleAt: scheduleAt,
          );

      await goTo(LastWishesStep.done);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to enable. Please try again.');
      await _persistLocal();
      return false;
    } finally {
      state = state.copyWith(submitting: false);
      await _persistLocal();
    }
  }

  // ────────────────────── Reset ──────────────────────

  Future<void> resetAllAndSyncClear() async {
    state = LastWishesState.initial(noteId: state.noteId);
    await _persistLocal();
    await syncToBackend(); // ✅ 云端也清空（可选）
    await _repo.clearDraft();
  }

  void setMessageNote(String v) {
    final t = v.trim();
    state = state.copyWith(
      messageNote: t.isEmpty ? null : t,
      clearMessageNote: t.isEmpty, // ✅ 输入空就清
      clearError: true,
    );
    _persistLocal(scheduleSync: true);
  }

  void clearMessageNote() {
    state = state.copyWith(clearMessageNote: true, clearError: true);
    _persistLocal(scheduleSync: true);
  }

  Future<void> _persistLocal({bool scheduleSync = false}) async {
    await _repo.saveDraft(state);
    if (scheduleSync) _scheduleSync();
  }

  DateTime _calcScheduleAt(int years) {
    final now = DateTime.now();
    return DateTime(
      now.year + years,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );
  }
}
