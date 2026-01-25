// lib/provider/inspiration/inspiration_wall_provider.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:lifecapsule8_app/crypto/crypto_state.dart';
import 'package:lifecapsule8_app/crypto/note_cipher.dart';
import 'package:lifecapsule8_app/crypto/crypto_provider.dart';

import 'package:lifecapsule8_app/hive/hive_boxes.dart';
import 'package:lifecapsule8_app/provider/inspiration/inspiration_state.dart';
import 'package:lifecapsule8_app/provider/note/note_provider.dart';

final inspirationProvider =
    NotifierProvider<InspirationNotifier, InspirationState>(() {
      return InspirationNotifier();
    });

class InspirationNotifier extends Notifier<InspirationState> {
  static const String _hiveKey = 'inspiration_default';

  // ✅ noteId key（每用户唯一 inspiration note）
  static const String _noteIdKey = 'inspiration_note_id';

  late final Box<String> _box = Hive.box<String>(HiveBoxes.inspirationBox);
  final _uuid = const Uuid();

  Timer? _persistDebounce;
  Timer? _syncDebounce;

  bool _didInit = false;
  bool _syncing = false;

  String _loadOrCreateNoteId() {
    final existing = _box.get(_noteIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = _uuid.v4();
    _box.put(_noteIdKey, id);
    return id;
  }

  @override
  InspirationState build() {
    ref.onDispose(() {
      _persistDebounce?.cancel();
      _persistDebounce = null;
      _syncDebounce?.cancel();
      _syncDebounce = null;
    });

    final noteId = _loadOrCreateNoteId();

    // 监听 masterKey 从无到有时，自动重新 load（用于解密恢复）
    ref.listen<CryptoState>(cryptoProvider, (prev, next) {
      final prevHasKey = prev?.hasMasterKey ?? false;
      final nextHasKey = next.hasMasterKey;

      if (!prevHasKey && nextHasKey) {
        unawaited(load());
      }
    });

    Future.microtask(_ensureInit);
    return InspirationState.initial(noteId: noteId);
  }

  Future<void> _ensureInit() async {
    if (_didInit) return;
    _didInit = true;

    await load();

    // ✅ 可选：启动后也尝试同步一次（把本地内容补上云端）
    _scheduleSync();
  }

  Future<void> load() async {
    try {
      state = state.copyWith(loading: true, clearError: true);

      final raw = _box.get(_hiveKey);
      if (raw == null || raw.isEmpty) {
        state = state.copyWith(loading: false, content: '');
        return;
      }

      final masterKey = ref.read(cryptoProvider.notifier).masterKey;

      if (masterKey != null && masterKey.isNotEmpty) {
        final plain = NoteCipher.decryptFromCompactString(
          masterKey: masterKey,
          raw: raw,
        );
        final obj = jsonDecode(plain) as Map<String, dynamic>;

        state = state.copyWith(
          loading: false,
          content: (obj['content'] as String?) ?? '',
          cursorOffset: obj['cursorOffset'] as int?,
          scrollTop: (obj['scrollTop'] as num?)?.toDouble(),
        );
        return;
      }

      // 没 masterKey：尝试当明文 JSON 读
      try {
        final obj = jsonDecode(raw) as Map<String, dynamic>;
        state = state.copyWith(
          loading: false,
          content: (obj['content'] as String?) ?? '',
          cursorOffset: obj['cursorOffset'] as int?,
          scrollTop: (obj['scrollTop'] as num?)?.toDouble(),
        );
      } catch (_) {
        state = state.copyWith(
          loading: false,
          content: '',
          error:
              'Inspiration wall is encrypted, but no master key is available.',
        );
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void updateContent(String content, {int? cursorOffset, double? scrollTop}) {
    state = state.copyWith(
      content: content,
      cursorOffset: cursorOffset ?? state.cursorOffset,
      scrollTop: scrollTop ?? state.scrollTop,
      loading: false,
      clearError: true,
    );

    _schedulePersist();
    _scheduleSync(); // ✅ 修改即上云（debounce）
  }

  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(persistNow());
    });
  }

  void _scheduleSync() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        await syncToBackend();
      } catch (_) {
        // swallow：自动同步失败不打断用户
      }
    });
  }

  Future<void> persistNow() async {
    try {
      final payload = <String, dynamic>{
        'version': 1,
        'content': state.content,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
        if (state.cursorOffset != null) 'cursorOffset': state.cursorOffset,
        if (state.scrollTop != null) 'scrollTop': state.scrollTop,
      };

      final plainJson = jsonEncode(payload);
      final masterKey = ref.read(cryptoProvider.notifier).masterKey;

      // 没 masterKey：降级存明文 JSON
      if (masterKey == null || masterKey.isEmpty) {
        await _box.put(_hiveKey, plainJson);
        return;
      }

      final enc = NoteCipher.encryptToCompactString(
        masterKey: masterKey,
        plaintext: plainJson,
      );
      await _box.put(_hiveKey, enc);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> syncToBackend() async {
    if (_syncing) return;
    _syncing = true;

    try {
      state = state.copyWith(syncing: true);

      final meta = <String, dynamic>{
        'kind': 'INSPIRATION',
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
        if (state.cursorOffset != null) 'cursorOffset': state.cursorOffset,
        if (state.scrollTop != null) 'scrollTop': state.scrollTop,
      };

      await ref
          .read(noteProvider.notifier)
          .upsertBusinessNote(
            noteId: state.noteId, // ✅ UUID（存 Hive）
            noteType: 'INSPIRATION',
            plainText: state.content,
            meta: meta,
          );
    } finally {
      _syncing = false;
      state = state.copyWith(syncing: false);
    }
  }
}
