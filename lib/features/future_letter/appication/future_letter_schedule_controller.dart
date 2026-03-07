import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/future_letter/appication/future_letter_draft_store.dart';

final futureLetterScheduleControllerProvider =
    AsyncNotifierProvider<
      FutureLetterScheduleController,
      FutureLetterScheduleState
    >(FutureLetterScheduleController.new);

class FutureLetterScheduleState {
  final bool loading;
  final bool saving;
  final String? error;

  /// UI picked local datetime
  final DateTime? pickedLocal;

  const FutureLetterScheduleState({
    this.loading = true,
    this.saving = false,
    this.error,
    this.pickedLocal,
  });

  FutureLetterScheduleState copyWith({
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
    DateTime? pickedLocal,
    bool clearPickedLocal = false,
  }) {
    return FutureLetterScheduleState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      pickedLocal: clearPickedLocal ? null : (pickedLocal ?? this.pickedLocal),
    );
  }

  bool get hasPicked => pickedLocal != null;
}

class FutureLetterScheduleController
    extends AsyncNotifier<FutureLetterScheduleState> {
  @override
  Future<FutureLetterScheduleState> build() async {
    // ✅ watch：current draft 切换时，Schedule 也会刷新
    final draft = ref.watch(futureLetterDraftStoreProvider).current;

    if (draft == null) {
      return const FutureLetterScheduleState(
        loading: false,
        error: 'No current future letter draft',
      );
    }

    DateTime? picked;
    final iso = (draft.sendAtIso ?? '').trim();
    if (iso.isNotEmpty) {
      picked = DateTime.tryParse(iso)?.toLocal();
    }

    return FutureLetterScheduleState(loading: false, pickedLocal: picked);
  }

  void setPickedLocal(DateTime dt) {
    final s = state.value;
    if (s == null) return;

    state = AsyncData(s.copyWith(pickedLocal: dt, clearError: true));

    // 写回 store（内存）
    ref
        .read(futureLetterDraftStoreProvider.notifier)
        .setSendAtLocalInMemory(dt);
  }

  bool get canNext {
    final s = state.value;
    return s != null && s.pickedLocal != null && !s.saving;
  }

  Future<void> persistBeforeLeave() async {
    final s = state.value;
    if (s == null) return;
    if (s.saving) return;

    state = AsyncData(s.copyWith(saving: true, clearError: true));

    try {
      await ref
          .read(futureLetterDraftStoreProvider.notifier)
          .persistNowIfNeeded();
      final latest = state.value ?? s;
      state = AsyncData(latest.copyWith(saving: false));
    } catch (e) {
      final latest = state.value ?? s;
      state = AsyncData(latest.copyWith(saving: false, error: e.toString()));
    }
  }
}
