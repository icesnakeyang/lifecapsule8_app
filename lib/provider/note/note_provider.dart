// lib/provider/note/note_provider.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:lifecapsule8_app/api/api.dart';
import 'package:lifecapsule8_app/crypto/crypto_provider.dart';
import 'package:lifecapsule8_app/crypto/note_cipher.dart';
import 'package:lifecapsule8_app/hive/hive_boxes.dart';
import 'package:lifecapsule8_app/provider/note/local_note.dart';
import 'package:lifecapsule8_app/provider/note/note_state.dart';
import 'package:lifecapsule8_app/utils/dt_localized.dart';

final noteProvider = NotifierProvider<NoteNotifier, NoteState>(() {
  return NoteNotifier();
});

class NoteNotifier extends Notifier<NoteState> {
  late final Box<String> _notesBox = Hive.box<String>(HiveBoxes.notes);

  Uint8List? get _masterKey => ref.read(cryptoProvider.notifier).masterKey;

  bool _syncing = false;
  bool _forceClearCurrent = false;

  // -------------------------
  // Public helpers used by UI
  // -------------------------

  Future<void> clearCurrentNote() async {
    _forceClearCurrent = true;
    state = state.copyWith(currentNote: null);
    await Future.delayed(Duration.zero);
  }

  void setCurrentNoteById(String id) {
    final raw = _notesBox.get(id);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (map.containsKey('enc')) {
          final enc = map['enc'] as String;
          final key = _masterKey;
          String content;
          if (key != null) {
            try {
              content = NoteCipher.decryptFromCompactString(
                masterKey: key,
                raw: enc,
                aad: Uint8List.fromList(utf8.encode(id)),
              );
            } catch (_) {
              content = '[Decryption failed]';
            }
          } else {
            content = '[Encrypted note]';
          }
          map['content'] = content;
        }
        final fresh = LocalNote.fromJson(map);
        state = state.copyWith(currentNote: fresh);
        return;
      } catch (_) {}
    }
    final found = state.notes.where((n) => n.id == id).toList();
    if (found.isNotEmpty) {
      state = state.copyWith(currentNote: found.first);
      return;
    }
    final cur = state.currentNote;
    if (cur != null && cur.id == id) {
      return;
    }
    state = state.copyWith(currentNote: null);
  }

  bool isNoteEncrypted(String noteId) {
    final raw = _notesBox.get(noteId);
    if (raw == null || raw.isEmpty) return false;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final enc = map['enc'] as String?;
      return enc != null && enc.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<LocalNote> createEmptyCurrentNote() async {
    final noteId = 'note_${DateTime.now().microsecondsSinceEpoch}';
    await upsertBusinessNote(
      noteId: noteId,
      noteType: 'PRIVATE_NOTE',
      plainText: '', // 空内容：只创建 current，不落盘（见 upsertBusinessNote）
      meta: const {},
    );
    // upsertBusinessNote 会因为空内容 return，所以这里手动建一个 currentNote
    final now = DateTime.now();
    final local = LocalNote(
      id: noteId,
      type: 'PRIVATE_NOTE',
      content: '',
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      isDeleted: false,
      version: 1,
      serverNoteId: null,
    );
    state = state.copyWith(currentNote: local);
    return local;
  }

  Future<void> saveCurrentNoteAsNewFromText(String text) async {
    final noteId = 'note_${DateTime.now().microsecondsSinceEpoch}';
    // 这里允许空文本先创建（不落盘），但 currentNote 要有
    final now = DateTime.now();
    final local = LocalNote(
      id: noteId,
      type: 'PRIVATE_NOTE',
      content: text,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      isDeleted: false,
      version: 1,
      serverNoteId: null,
    );
    state = state.copyWith(currentNote: local);

    // 有内容才真正落盘 + 同步
    if (text.trim().isNotEmpty) {
      await saveOrDeleteNoteById(noteId, text);
    }
  }

  Future<void> updateNoteById(String noteId, String text) async {
    final cur = state.currentNote;
    if (cur != null && cur.id == noteId && cur.content == text) {
      return; // ✅ 文本没变，不要把 isSynced 置 false
    }

    final now = DateTime.now();
    final notes = [...state.notes];

    final idx = notes.indexWhere((n) => n.id == noteId);
    if (idx >= 0) {
      notes[idx] = notes[idx].copyWith(
        content: text,
        updatedAt: now,
        isSynced: false,
      );
    }

    if (cur != null && cur.id == noteId) {
      state = state.copyWith(
        notes: notes,
        currentNote: cur.copyWith(
          content: text,
          updatedAt: now,
          isSynced: false,
        ),
      );
    } else {
      state = state.copyWith(notes: notes);
    }
  }

  Future<void> autoSaveOnBackground(String noteId, String text) async {
    await saveOrDeleteNoteById(noteId, text);
  }

  Future<void> saveOrDeleteNoteById(String noteId, String text) async {
    final content = text.trim();

    // 为空：如果本地已经有记录，则删除；如果只是临时新建的 currentNote，则清 current
    if (content.isEmpty) {
      final raw = _notesBox.get(noteId);
      if (raw != null) {
        await deleteNoteById(noteId);
      } else {
        final cur = state.currentNote;
        if (cur != null && cur.id == noteId) {
          clearCurrentNote();
        }
      }
      return;
    }

    // 非空：落盘 + 触发同步
    await upsertBusinessNote(
      noteId: noteId,
      noteType: 'PRIVATE_NOTE',
      plainText: content,
      meta: const {},
    );

    // 同时确保 currentNote 指向它
    setCurrentNoteById(noteId);
  }

  Future<void> deleteNoteById(String noteId) async {
    final raw = _notesBox.get(noteId);
    if (raw == null || raw.isEmpty) {
      // 没落盘的临时 note：直接从 state 清掉
      final notes = state.notes.where((n) => n.id != noteId).toList();
      final cur = state.currentNote;
      state = state.copyWith(
        notes: notes,
        currentNote: (cur != null && cur.id == noteId) ? null : cur,
      );
      return;
    }

    final map = jsonDecode(raw) as Map<String, dynamic>;
    map['isDeleted'] = true;
    map['isSynced'] = false;
    map['updatedAt'] = toIso8601WithOffset(DateTime.now());
    await _notesBox.put(noteId, jsonEncode(map));

    // UI 移除
    final notes = state.notes.where((n) => n.id != noteId).toList();
    final cur = state.currentNote;
    state = state.copyWith(
      notes: notes,
      currentNote: (cur != null && cur.id == noteId) ? null : cur,
    );
  }

  Iterable<Map<String, dynamic>> _iterPendingRecords() sync* {
    for (final raw in _notesBox.values) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final isSynced = map['isSynced'] as bool? ?? false;
        if (!isSynced) yield map;
      } catch (_) {}
    }
  }

  Future<void> _uploadRecordToServer(Map<String, dynamic> m) async {
    final clientNoteId = m['id'] as String?;
    if (clientNoteId == null || clientNoteId.isEmpty) return;

    final encRaw = m['enc'] as String?;
    final isDeleted = m['isDeleted'] as bool? ?? false;

    // ✅ 只有有 enc 才上云（你现有策略）
    if (encRaw == null || encRaw.isEmpty) return;

    late final NoteCipherParts parts;
    try {
      parts = NoteCipher.unpackCompactString(encRaw);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('unpackCompactString failed for note=$clientNoteId: $e');
        debugPrint('$st');
      }
      return;
    }

    String normalizeIso(dynamic v) {
      if (v == null) return toIso8601WithOffset(DateTime.now());
      if (v is DateTime) return toIso8601WithOffset(v);
      final s = v.toString();
      final hasOffset =
          s.endsWith('Z') || RegExp(r'.*[+-]\d\d:\d\d$').hasMatch(s);
      return hasOffset ? s : '$s+00:00';
    }

    final metaObj = m['meta'];
    String? metaJson;
    if (metaObj is Map) {
      metaJson = jsonEncode(metaObj);
    } else if (metaObj is String && metaObj.trim().isNotEmpty) {
      metaJson = metaObj;
    }

    final params = <String, dynamic>{
      "noteId": m['serverNoteId'],
      "clientNoteId": clientNoteId,
      "entityType": m['type'] ?? 'PRIVATE_NOTE',
      "cipherText": parts.ciphertext,
      "encAlg": "AES_GCM",
      "ivB64": parts.iv,
      "tagB64": parts.authTag,
      if (metaJson != null) "metaJson": metaJson,
      if (m['title'] != null) "title": m['title'],
      "createdAt": normalizeIso(m['createdAt']),
      "updatedAt": normalizeIso(m['updatedAt']),
      "deleted": isDeleted,
    };

    final result = await Api.apiSaveNote(params);
    final code = int.tryParse(result['code']?.toString() ?? '') ?? -1;
    if (code != 0) return;

    final serverNoteId = result['data']?['noteId'];

    if (isDeleted) {
      await _notesBox.delete(clientNoteId);
      return;
    }

    m['isSynced'] = true;
    if (serverNoteId != null) m['serverNoteId'] = serverNoteId;
    await _notesBox.put(clientNoteId, jsonEncode(m));
    final prevNotes = state.notes;
    final idx = prevNotes.indexWhere((e) => e.id == clientNoteId);

    if (idx >= 0) {
      final updated = [...prevNotes];
      updated[idx] = updated[idx].copyWith(
        isSynced: true,
        serverNoteId: serverNoteId?.toString() ?? updated[idx].serverNoteId,
      );

      final cur = state.currentNote;
      state = state.copyWith(
        notes: updated,
        currentNote: (cur != null && cur.id == clientNoteId)
            ? cur.copyWith(
                isSynced: true,
                serverNoteId: serverNoteId?.toString() ?? cur.serverNoteId,
              )
            : cur,
      );
    } else {
      // 没在列表里就至少保证 currentNote 正确
      final cur = state.currentNote;
      if (cur != null && cur.id == clientNoteId) {
        state = state.copyWith(
          currentNote: cur.copyWith(
            isSynced: true,
            serverNoteId: serverNoteId?.toString() ?? cur.serverNoteId,
          ),
        );
      }
    }
  }

  Future<void> syncToCloud() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final key = _masterKey;
      if (key == null) return;

      for (final m in _iterPendingRecords()) {
        await _uploadRecordToServer(m);
      }

      state = build();
    } finally {
      _syncing = false;
    }
  }

  @override
  NoteState build() {
    ref.watch(cryptoProvider);

    final key = _masterKey;

    final notes =
        _notesBox.values
            .map((raw) {
              final map = jsonDecode(raw) as Map<String, dynamic>;
              if (map.containsKey('enc')) {
                final enc = map['enc'] as String;
                final noteId = map['id'] as String?;
                String content;
                if (key != null && noteId != null) {
                  try {
                    content = NoteCipher.decryptFromCompactString(
                      masterKey: key,
                      raw: enc,
                      aad: Uint8List.fromList(utf8.encode(noteId)),
                    );
                  } catch (_) {
                    content = '[Decryption failed]';
                  }
                } else {
                  content = '[Encrypted note]';
                }
                map['content'] = content;
              }
              return LocalNote.fromJson(map);
            })
            .where((n) => !n.isDeleted)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final prev = stateOrNull;
    LocalNote? nextCurrent;
    if (_forceClearCurrent) {
      nextCurrent = null;
    } else {
      final prevId = prev?.currentNote?.id;
      if (prevId != null) {
        for (final n in notes) {
          if (n.id == prevId) {
            nextCurrent = n;
            break;
          }
        }
      }
      nextCurrent ??= (notes.isNotEmpty ? notes.first : null);
    }

    return prev == null
        ? NoteState(notes: notes, currentNote: nextCurrent)
        : prev.copyWith(notes: notes, currentNote: nextCurrent);
  }

  // -------------------------
  // Core upsert used by other modules
  // -------------------------

  Future<void> upsertBusinessNote({
    required String noteId,
    required String noteType,
    required String plainText,
    required Map<String, dynamic> meta,
  }) async {
    final content = plainText.trim();
    if (content.isEmpty) return;

    final now = DateTime.now();
    final key = _masterKey;

    final raw = _notesBox.get(noteId);

    if (raw != null) {
      final existingMap = jsonDecode(raw) as Map<String, dynamic>;
      final bool wasEncrypted = existingMap.containsKey('enc');
      if (wasEncrypted && key == null) return;
    }

    Map<String, dynamic> map;
    int newVersion;

    if (raw == null) {
      map = <String, dynamic>{
        'id': noteId,
        'serverNoteId': null,
        'isSynced': false,
        'isDeleted': false,
        'version': 1,
        'type': noteType,
        'meta': meta,
        'createdAt': toIso8601WithOffset(now),
        'updatedAt': toIso8601WithOffset(now),
      };
      newVersion = 1;
    } else {
      map = jsonDecode(raw) as Map<String, dynamic>;
      final int oldVersion = map['version'] as int? ?? 1;
      newVersion = oldVersion + 1;

      map['updatedAt'] = toIso8601WithOffset(now);
      map['isSynced'] = false;
      map['version'] = newVersion;

      map['type'] = noteType;
      map['meta'] = meta;
    }

    if (key != null) {
      final enc = NoteCipher.encryptToCompactString(
        masterKey: key,
        plaintext: content,
        aad: Uint8List.fromList(utf8.encode(noteId)),
      );
      map['enc'] = enc;
      map.remove('content');
    } else {
      map['content'] = content;
      map.remove('enc');
    }

    await _notesBox.put(noteId, jsonEncode(map));

    final local = LocalNote.fromJson({...map, 'content': content});
    final existsIndex = state.notes.indexWhere((n) => n.id == noteId);

    if (existsIndex < 0) {
      state = state.copyWith(
        notes: [local, ...state.notes],
        currentNote: local,
      );
    } else {
      final updated = [...state.notes];
      updated[existsIndex] = updated[existsIndex].copyWith(
        content: content,
        updatedAt: now,
        isSynced: false,
        version: newVersion,
        type: noteType,
      );
      state = state.copyWith(
        notes: updated,
        currentNote: state.currentNote?.id == noteId
            ? local
            : state.currentNote,
      );
    }
  }
}
