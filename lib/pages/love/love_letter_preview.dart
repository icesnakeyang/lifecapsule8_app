// love_letter_preview.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifecapsule8_app/provider/love_letter/love_letter_provider.dart';
import 'package:lifecapsule8_app/provider/note/note_provider.dart';

class LoveLetterPreview extends ConsumerWidget {
  const LoveLetterPreview({super.key});

  String _sendModeText(String? mode) {
    switch (mode) {
      case 'PRIMARY_COUNTDOWN':
        return 'Primary countdown';
      case 'INSTANTLY':
        return 'Send instantly';
      case 'SPECIFIC_TIME':
      default:
        return 'Specific time';
    }
  }

  /// PASSCODE / QA / NONE
  String _passcodeModeText(String? mode) {
    switch (mode) {
      case 'PASSCODE':
        return 'Simple passcode';
      case 'QA':
        return 'Q&A passcode';
      case 'NONE':
      default:
        return 'No passcode';
    }
  }

  String? _qaQuestionFromPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final q = (map['q'] as String?)?.trim();
      return (q == null || q.isEmpty) ? null : q;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final noteId = args?['noteId'] as String?;

    final noteState = ref.watch(noteProvider);
    final loveState = ref.watch(loveLetterProvider);

    final draft = (noteId == null) ? null : loveState.draftsByNoteId[noteId];

    final sendMode = draft?.sendMode ?? 'SPECIFIC_TIME';
    final sendModeText = _sendModeText(sendMode);

    final sendAt = draft?.sendAtIso == null
        ? null
        : DateTime.tryParse(draft!.sendAtIso!);

    final sendAtText = (sendMode == 'SPECIFIC_TIME')
        ? (sendAt == null
              ? 'Not set'
              : DateFormat('EEE, d MMM yyyy • HH:mm').format(sendAt.toLocal()))
        : '-';

    final passMode = draft?.passcodeMode ?? 'NONE';
    final passModeText = _passcodeModeText(passMode);
    final qaQ = passMode == 'QA'
        ? _qaQuestionFromPayload(draft?.passcode)
        : null;

    final note = (noteId == null)
        ? null
        : noteState.notes.cast<dynamic>().firstWhere(
            (n) => n.id == noteId,
            orElse: () => null,
          );

    final content = note?.content ?? '(Letter not found)';

    final toLine = () {
      if (draft == null) return 'To: -';
      final toName = (draft.toName ?? '').trim();
      if (toName.isNotEmpty) return 'To: $toName';

      if (draft.toType == 'USER' && (draft.nickname?.isNotEmpty ?? false)) {
        return 'To: ${draft.nickname}';
      }
      if (draft.toType == 'EMAIL' && (draft.email?.isNotEmpty ?? false)) {
        return 'To: ${draft.email}';
      }
      return 'To: -';
    }();

    final fromLine = () {
      final v = (draft?.fromName ?? '').trim();
      return v.isEmpty ? 'From: -' : 'From: $v';
    }();

    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toLine,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(fromLine, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Send mode: $sendModeText',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Send at: $sendAtText',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Passcode: $passModeText',
                                style: const TextStyle(fontSize: 13),
                              ),
                              if (passMode == 'QA' && qaQ != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Question: $qaQ',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                              // ❗注意：不要在 preview 暴露答案/口令明文
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.04),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      content,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (noteId == null) return;

                        try {
                          await ref
                              .read(loveLetterProvider.notifier)
                              .confirmSend(noteId);

                          if (!context.mounted) return;
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Confirm failed: $e')),
                          );
                        }
                      },
                      child: const Text('Confirm send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
