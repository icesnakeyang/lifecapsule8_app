import 'package:lifecapsule8_app/provider/future/future_letter_draft.dart';

class FutureLetterState {
  final FutureLetterDraft? currentFutureLetter;
  final List<FutureLetterDraft> futureLetterList;
  final bool loading;
  final String? errMsg;

  const FutureLetterState({
    required this.currentFutureLetter,
    required this.futureLetterList,
    required this.loading,
    this.errMsg,
  });

  factory FutureLetterState.initial() => const FutureLetterState(
    currentFutureLetter: null,
    futureLetterList: <FutureLetterDraft>[],
    loading: false,
    errMsg: null,
  );

  FutureLetterState copyWith({
    FutureLetterDraft? currentFutureLetter,
    List<FutureLetterDraft>? futureLetterList,
    bool? loading,
    String? errMsg,
    bool clearCurrentFutureLetter = false,
    bool clearErrMsg = false,
  }) {
    return FutureLetterState(
      currentFutureLetter: clearCurrentFutureLetter
          ? null
          : (currentFutureLetter ?? this.currentFutureLetter),
      futureLetterList: futureLetterList ?? this.futureLetterList,
      loading: loading ?? this.loading,
      errMsg: clearErrMsg ? null : (errMsg ?? this.errMsg),
    );
  }
}
