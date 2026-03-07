import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final loveLetterPreviewControllerProvider =
    AsyncNotifierProvider<LoveLetterPreviewController, LoveLetterPreviewState>(
      LoveLetterPreviewController.new,
    );

class LoveLetterPreviewState {
  final bool opening;
  final bool confirming;
  final String? error;

  final NoteBase? note;

  // derived display fields
  final String toLine;
  final String fromLine;

  final String sendModeText;
  final String sendAtText;

  final String protectionText;
  final String? qaQuestion;

  const LoveLetterPreviewState({
    this.opening = true,
    this.confirming = false,
    this.error,
    this.note,
    this.toLine = 'To: -',
    this.fromLine = 'From: -',
    this.sendModeText = '-',
    this.sendAtText = '-',
    this.protectionText = '-',
    this.qaQuestion,
  });

  LoveLetterPreviewState copyWith({
    bool? opening,
    bool? confirming,
    String? error,
    bool clearError = false,
    NoteBase? note,
    String? toLine,
    String? fromLine,
    String? sendModeText,
    String? sendAtText,
    String? protectionText,
    String? qaQuestion,
    bool clearQaQuestion = false,
  }) {
    return LoveLetterPreviewState(
      opening: opening ?? this.opening,
      confirming: confirming ?? this.confirming,
      error: clearError ? null : (error ?? this.error),
      note: note ?? this.note,
      toLine: toLine ?? this.toLine,
      fromLine: fromLine ?? this.fromLine,
      sendModeText: sendModeText ?? this.sendModeText,
      sendAtText: sendAtText ?? this.sendAtText,
      protectionText: protectionText ?? this.protectionText,
      qaQuestion: clearQaQuestion ? null : (qaQuestion ?? this.qaQuestion),
    );
  }
}

class LoveLetterPreviewController
    extends AsyncNotifier<LoveLetterPreviewState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  @override
  Future<LoveLetterPreviewState> build() async {
    return const LoveLetterPreviewState(opening: true);
  }

  Future<void> open({required String noteId}) async {
    state = AsyncData(
      (state.value ?? const LoveLetterPreviewState()).copyWith(
        opening: true,
        clearError: true,
      ),
    );

    try {
      final note = await _repo.getById(noteId);
      if (note == null || note.kind != NoteKind.loveLetter) {
        throw Exception('Love letter not found: $noteId');
      }

      final meta = note.meta;

      final toLine = _buildToLine(meta);
      final fromLine = _buildFromLine(meta);

      final sendMode =
          (meta['sendMode'] as String?)?.toUpperCase() ?? 'SPECIFIC_TIME';
      final sendModeText = _sendModeText(sendMode);

      final sendAtText = _sendAtText(sendMode, meta['sendAtIso'] as String?);

      final passMode =
          (meta['passcodeMode'] as String?)?.toUpperCase() ?? 'NONE';
      final protectionText = _passcodeModeText(passMode);
      final qaQuestion = passMode == 'QA'
          ? _qaQuestion(meta['passcodePayload'] as String?)
          : null;

      state = AsyncData(
        (state.value ?? const LoveLetterPreviewState()).copyWith(
          opening: false,
          note: note,
          toLine: toLine,
          fromLine: fromLine,
          sendModeText: sendModeText,
          sendAtText: sendAtText,
          protectionText: protectionText,
          qaQuestion: qaQuestion,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? const LoveLetterPreviewState()).copyWith(
          opening: false,
          error: e.toString(),
        ),
      );
    }
  }

  // 你后面会把 confirmSend 迁到新版 send_task 体系里
  // 这里先只做“校验 + 标记已确认(可选)”，真正 enqueue 你再接 sendTaskProvider
  Future<void> confirmAndSend() async {
    final s = state.value;
    final note = s?.note;
    if (s == null || note == null) return;
    if (s.confirming) return;

    state = AsyncData(s.copyWith(confirming: true, clearError: true));

    try {
      _validateMeta(note.meta);

      // TODO: enqueue send task（接你新版 send_task builder）
      // await ref.read(sendTaskProvider.notifier).enqueue(...)

      state = AsyncData(
        (state.value ?? s).copyWith(confirming: false, clearError: true),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? s).copyWith(confirming: false, error: e.toString()),
      );
    }
  }

  // --------- helpers ---------

  String _sendModeText(String mode) {
    switch (mode) {
      case 'PRIMARY_COUNTDOWN':
        return 'Primary Countdown';
      case 'INSTANTLY':
        return 'Send Instantly';
      case 'LATER':
        return 'Decide Later';
      case 'SPECIFIC_TIME':
      default:
        return 'Specific Date & Time';
    }
  }

  String _passcodeModeText(String mode) {
    switch (mode) {
      case 'PASSCODE':
        return 'Simple Passcode';
      case 'QA':
        return 'Question & Answer';
      case 'NONE':
      default:
        return 'No Protection';
    }
  }

  String _sendAtText(String sendMode, String? iso) {
    if (sendMode != 'SPECIFIC_TIME') return '-';
    if (iso == null || iso.trim().isEmpty) return 'Not set yet';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Invalid time';
    return DateFormat('EEE, d MMM yyyy • HH:mm').format(dt.toLocal());
  }

  String? _qaQuestion(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final q = (map['q'] as String?)?.trim();
      return (q == null || q.isEmpty) ? null : q;
    } catch (_) {
      return null;
    }
  }

  String _buildToLine(Map<String, dynamic> meta) {
    final toName = (meta['toName'] as String?)?.trim() ?? '';
    if (toName.isNotEmpty) return 'To: $toName';

    final toType = (meta['toType'] as String?)?.toUpperCase() ?? '';
    if (toType == 'USER') {
      final nickname = (meta['nickname'] as String?)?.trim() ?? '';
      if (nickname.isNotEmpty) return 'To: $nickname';
    } else if (toType == 'EMAIL') {
      final email = (meta['email'] as String?)?.trim() ?? '';
      if (email.isNotEmpty) return 'To: $email';
    }
    return 'To: -';
  }

  String _buildFromLine(Map<String, dynamic> meta) {
    final from = (meta['fromName'] as String?)?.trim() ?? '';
    return from.isEmpty ? 'From: -' : 'From: $from';
  }

  void _validateMeta(Map<String, dynamic> meta) {
    final toType = (meta['toType'] as String?)?.toUpperCase() ?? 'EMAIL';
    if (toType == 'USER') {
      final uid = (meta['userId'] as String?)?.trim() ?? '';
      if (uid.isEmpty) throw Exception('Recipient user not set');
    } else if (toType == 'EMAIL') {
      final email = (meta['email'] as String?)?.trim() ?? '';
      if (email.isEmpty) throw Exception('Recipient email not set');
    } else {
      throw Exception('Invalid recipient type: $toType');
    }

    final sendMode =
        (meta['sendMode'] as String?)?.toUpperCase() ?? 'SPECIFIC_TIME';
    const allowedSend = {
      'SPECIFIC_TIME',
      'PRIMARY_COUNTDOWN',
      'INSTANTLY',
      'LATER',
    };
    if (!allowedSend.contains(sendMode)) {
      throw Exception('Invalid send mode: $sendMode');
    }

    if (sendMode == 'SPECIFIC_TIME') {
      final iso = (meta['sendAtIso'] as String?)?.trim() ?? '';
      if (iso.isEmpty) throw Exception('Send time not set');
    }

    final passMode = (meta['passcodeMode'] as String?)?.toUpperCase() ?? 'NONE';
    const allowedPass = {'NONE', 'PASSCODE', 'QA'};
    if (!allowedPass.contains(passMode)) {
      throw Exception('Invalid protection mode: $passMode');
    }

    final payload = (meta['passcodePayload'] as String?)?.trim() ?? '';
    if (passMode == 'PASSCODE') {
      if (payload.isEmpty) throw Exception('Passcode not set');
    } else if (passMode == 'QA') {
      if (payload.isEmpty) throw Exception('Q&A not set');
      try {
        final map = jsonDecode(payload) as Map<String, dynamic>;
        final q = (map['q'] as String?)?.trim() ?? '';
        final a = (map['a'] as String?)?.trim() ?? '';
        if (q.isEmpty || a.isEmpty) throw Exception('Q&A not set');
      } catch (_) {
        throw Exception('Invalid Q&A payload');
      }
    }
  }
}
