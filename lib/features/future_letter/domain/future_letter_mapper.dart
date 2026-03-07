import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';
import 'future_letter_draft.dart';

class FutureLetterMapper {
  /// NoteBase → FutureLetterDraft
  static FutureLetterDraft fromNote(NoteBase note) {
    final meta = note.meta ?? const <String, dynamic>{};

    return FutureLetterDraft(
      noteId: note.id,
      updatedAt: note.updatedAt,
      content: note.content ?? '',
      userCode: meta['userCode'] as String?,
      userId: meta['userId'] as String?,
      nickname: meta['nickname'] as String?,
      email: meta['email'] as String?,
      toName: meta['toName'] as String?,
      fromName: meta['fromName'] as String?,
      sendAtIso: meta['sendAtIso'] as String?,
    );
  }

  /// FutureLetterDraft → NoteBase
  static NoteBase toNote({
    required FutureLetterDraft draft,
    required String userId,
  }) {
    final now = DateTime.now();

    final meta = <String, dynamic>{
      'kind': 'FUTURE_LETTER',
      if ((draft.userCode ?? '').trim().isNotEmpty) 'userCode': draft.userCode,
      if ((draft.userId ?? '').trim().isNotEmpty) 'userId': draft.userId,
      if ((draft.nickname ?? '').trim().isNotEmpty) 'nickname': draft.nickname,
      if ((draft.email ?? '').trim().isNotEmpty) 'email': draft.email,
      if ((draft.toName ?? '').trim().isNotEmpty) 'toName': draft.toName,
      if ((draft.fromName ?? '').trim().isNotEmpty) 'fromName': draft.fromName,
      if ((draft.sendAtIso ?? '').trim().isNotEmpty)
        'sendAtIso': draft.sendAtIso,
      'updatedAtMs': now.millisecondsSinceEpoch,
    };

    return NoteBase(
      id: draft.noteId,
      userId: userId,
      kind: NoteKind.futureLetter,
      content: draft.content,
      meta: meta,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }
}
