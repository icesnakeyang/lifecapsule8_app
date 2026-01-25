import 'package:lifecapsule8_app/provider/love_letter/love_letter_draft.dart';

class LoveLetterState {
  const LoveLetterState({this.draftsByNoteId = const {}, this.currentDraft});

  final Map<String, LoveLetterDraft> draftsByNoteId;
  final LoveLetterDraft? currentDraft;

  LoveLetterState copyWith({
    Map<String, LoveLetterDraft>? draftsByNoteId,
    LoveLetterDraft? currentDraft,
    bool clearCurrentDraft = false,
  }) {
    return LoveLetterState(
      draftsByNoteId: draftsByNoteId ?? this.draftsByNoteId,
      currentDraft: clearCurrentDraft
          ? null
          : (currentDraft ?? this.currentDraft),
    );
  }
}
