// lib/provider/last_wishes/last_wishes_repo.dart
import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:lifecapsule8_app/hive/hive_boxes.dart';
import 'last_wishes_state.dart';

class LastWishesRepo {
  static const _keyDraft = 'draft'; // 你也可以用 userId 做 key

  Box<String> get _box => Hive.box<String>(HiveBoxes.lastWishes);

  Future<void> saveDraft(LastWishesState s) async {
    final map = {
      'noteId': s.noteId,
      'content': s.content,
      'destination': s.destination.name,
      'recipientEmail': s.recipientEmail,
      'waitingYears': s.waitingYears,
      'enabled': s.enabled,
      'messageNote': s.messageNote,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    };
    await _box.put(_keyDraft, jsonEncode(map));
  }

  LastWishesState? loadDraftIntoState() {
    final raw = _box.get(_keyDraft);
    if (raw == null || raw.isEmpty) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final destStr = (m['destination'] as String?) ?? 'person';
    final dest = destStr == 'world'
        ? LastWishesDestination.world
        : LastWishesDestination.person;
    return LastWishesState(
      noteId: (m['noteId'] as String?) ?? 'last_wishes',
      step: LastWishesStep.intro, // 重新进入时一般从 intro/preview 由你决定
      content: (m['content'] ?? '') as String,
      destination: dest,
      recipientEmail: m['recipientEmail'] as String?,
      waitingYears: m['waitingYears'] as int?,
      enabled: (m['enabled'] ?? false) as bool,
      messageNote: m['messageNote'] as String?,
      submitting: false,
      error: null,
    );
  }

  Future<void> clearDraft() => _box.delete(_keyDraft);
}
