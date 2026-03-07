// lib/features/love_letter/application/love_letter_recipient_controller.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final loveLetterRecipientControllerProvider =
    AsyncNotifierProvider<
      LoveLetterRecipientController,
      LoveLetterRecipientState
    >(LoveLetterRecipientController.new);

class LoveLetterRecipientMeta {
  final String toType; // USER | EMAIL
  final String? userCode;
  final String? userId;
  final String? nickname;
  final String? email;
  final String? toName;
  final String? fromName;

  const LoveLetterRecipientMeta({
    this.toType = 'USER',
    this.userCode,
    this.userId,
    this.nickname,
    this.email,
    this.toName,
    this.fromName,
  });

  LoveLetterRecipientMeta copyWith({
    String? toType,
    String? userCode,
    String? userId,
    String? nickname,
    String? email,
    String? toName,
    String? fromName,
    bool clearEmail = false,
    bool clearUser = false,
  }) {
    return LoveLetterRecipientMeta(
      toType: toType ?? this.toType,
      userCode: clearUser ? null : (userCode ?? this.userCode),
      userId: clearUser ? null : (userId ?? this.userId),
      nickname: clearUser ? null : (nickname ?? this.nickname),
      email: clearEmail ? null : (email ?? this.email),
      toName: toName ?? this.toName,
      fromName: fromName ?? this.fromName,
    );
  }

  Map<String, dynamic> toMetaMap() => {
    'toType': toType,
    'userCode': userCode,
    'userId': userId,
    'nickname': nickname,
    'email': email,
    'toName': toName,
    'fromName': fromName,
  };

  static LoveLetterRecipientMeta fromMetaMap(Map<String, dynamic> m) {
    return LoveLetterRecipientMeta(
      toType: (m['toType'] as String?) ?? 'USER',
      userCode: m['userCode'] as String?,
      userId: m['userId'] as String?,
      nickname: m['nickname'] as String?,
      email: m['email'] as String?,
      toName: m['toName'] as String?,
      fromName: m['fromName'] as String?,
    );
  }
}

class LoveLetterRecipientState {
  final bool opening;
  final bool saving;
  final String? error;
  final String? noteId;
  final NoteBase? note;
  final LoveLetterRecipientMeta meta;

  const LoveLetterRecipientState({
    this.opening = true,
    this.saving = false,
    this.error,
    this.noteId,
    this.note,
    this.meta = const LoveLetterRecipientMeta(),
  });

  bool get canNext {
    final toType = meta.toType.toUpperCase();
    final hasRecipient =
        (toType == 'USER' && (meta.nickname ?? '').trim().isNotEmpty) ||
        (toType == 'EMAIL' && (meta.email ?? '').trim().isNotEmpty);
    final hasNames =
        (meta.toName ?? '').trim().isNotEmpty &&
        (meta.fromName ?? '').trim().isNotEmpty;
    return hasRecipient && hasNames;
  }

  LoveLetterRecipientState copyWith({
    bool? opening,
    bool? saving,
    String? error,
    String? noteId,
    NoteBase? note,
    LoveLetterRecipientMeta? meta,
    bool clearError = false,
  }) {
    return LoveLetterRecipientState(
      opening: opening ?? this.opening,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      noteId: noteId ?? this.noteId,
      note: note ?? this.note,
      meta: meta ?? this.meta,
    );
  }
}

class LoveLetterRecipientController
    extends AsyncNotifier<LoveLetterRecipientState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  Timer? _debounce;

  @override
  Future<LoveLetterRecipientState> build() async {
    ref.onDispose(() => _debounce?.cancel());
    return const LoveLetterRecipientState(opening: true);
  }

  Future<void> open({required String noteId}) async {
    state = AsyncData(
      (state.value ?? const LoveLetterRecipientState()).copyWith(
        opening: true,
        clearError: true,
      ),
    );

    try {
      final note = await _repo.getById(noteId);

      if (note == null || note.kind != NoteKind.loveLetter) {
        throw Exception('Love letter note not found: $noteId');
      }

      final metaMap = (note.meta);
      final meta = LoveLetterRecipientMeta.fromMetaMap(metaMap);

      state = AsyncData(
        (state.value ?? const LoveLetterRecipientState()).copyWith(
          opening: false,
          noteId: noteId,
          note: note,
          meta: meta,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? const LoveLetterRecipientState()).copyWith(
          opening: false,
          error: e.toString(),
        ),
      );
    }
  }

  void setToType(String toType) {
    final s = state.value;
    if (s == null) return;

    final upper = toType.toUpperCase();
    LoveLetterRecipientMeta next = s.meta.copyWith(toType: upper);

    if (upper == 'USER') {
      // 切回 USER：清 email
      next = next.copyWith(clearEmail: true);
    } else {
      // 切回 EMAIL：清 user
      next = next.copyWith(clearUser: true);
    }

    state = AsyncData(s.copyWith(meta: next, clearError: true));
    _scheduleSave();
  }

  void selectUser({
    required String userCode,
    required String nickname,
    String? userId,
  }) {
    final s = state.value;
    if (s == null) return;

    final next = s.meta.copyWith(
      toType: 'USER',
      userCode: userCode.trim().isEmpty ? null : userCode.trim(),
      nickname: nickname.trim().isEmpty ? null : nickname.trim(),
      userId: (userId ?? '').trim().isEmpty ? null : userId!.trim(),
      clearEmail: true,
    );

    state = AsyncData(s.copyWith(meta: next, clearError: true));
    _scheduleSave();
  }

  void updateLocal({String? email, String? toName, String? fromName}) {
    final s = state.value;
    if (s == null) return;

    final next = s.meta.copyWith(
      email: email,
      toName: toName,
      fromName: fromName,
    );

    state = AsyncData(s.copyWith(meta: next, clearError: true));
    _scheduleSave();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      save();
    });
  }

  Future<void> save() async {
    final s = state.value;
    if (s == null || s.noteId == null) return;
    if (s.saving) return;

    state = AsyncData(s.copyWith(saving: true, clearError: true));

    try {
      final cur = await _repo.getById(s.noteId!);
      if (cur == null) throw Exception('Note not found: ${s.noteId}');

      final mergedMeta = {...cur.meta, ...s.meta.toMetaMap()};

      await _repo.upsert(
        cur.copyWith(
          meta: mergedMeta,
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
