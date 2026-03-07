import 'package:lifecapsule8_app/features/future_letter/domain/future_letter_draft.dart';

class FutureLetterDraftStoreState {
  final List<FutureLetterDraft> list;
  final FutureLetterDraft? current;

  const FutureLetterDraftStoreState({
    required this.list,
    required this.current,
  });

  factory FutureLetterDraftStoreState.initial() =>
      const FutureLetterDraftStoreState(
        list: <FutureLetterDraft>[],
        current: null,
      );

  FutureLetterDraftStoreState copyWith({
    List<FutureLetterDraft>? list,
    FutureLetterDraft? current,
    bool clearCurrent = false,
  }) {
    return FutureLetterDraftStoreState(
      list: list ?? this.list,
      current: clearCurrent ? null : (current ?? this.current),
    );
  }
}
