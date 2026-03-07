import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:lifecapsule8_app/core/constants/hive_boxes.dart';
import 'package:pointycastle/export.dart';

import 'crypto_state.dart';
import 'note_cipher.dart';

final cryptoProvider = NotifierProvider<CryptoNotifier, CryptoState>(
  CryptoNotifier.new,
);

class CryptoNotifier extends Notifier<CryptoState> {
  static const String _kHasMnemonic = 'hasMnemonic';
  static const String _kCreatedAtMs = 'createdAtMs';
  static const String _kMasterKeyB64 = 'masterKeyB64';

  static const String _appSaltString = 'LifeCapsule8_MnemonicRoot_v1';

  late final Box _box;

  Uint8List? _masterKey; // 32 bytes
  Uint8List? get masterKey => _masterKey;

  @override
  CryptoState build() {
    _box = Hive.box(HiveBoxes.crypto);

    final hasMnemonic = (_box.get(_kHasMnemonic) as bool?) ?? false;
    final createdAtMs = _box.get(_kCreatedAtMs) as int?;
    final masterKeyB64 = _box.get(_kMasterKeyB64) as String?;

    if (masterKeyB64 != null && masterKeyB64.isNotEmpty) {
      try {
        _masterKey = base64Decode(masterKeyB64);
      } catch (_) {
        _masterKey = null;
      }
    }

    return CryptoState(
      hasMnemonic: hasMnemonic,
      hasMasterKey: _masterKey != null,
      createdAt: createdAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }

  Future<void> _saveState() async {
    await _box.put(_kHasMnemonic, state.hasMnemonic);

    if (state.createdAt != null) {
      await _box.put(_kCreatedAtMs, state.createdAt!.millisecondsSinceEpoch);
    } else {
      await _box.delete(_kCreatedAtMs);
    }

    // 你之前版本会落盘 masterKeyB64（方便“本机解锁”）
    // 若你后续想“绝不落盘”，可以删掉这段，并改为仅内存持有。
    if (_masterKey != null) {
      await _box.put(_kMasterKeyB64, base64Encode(_masterKey!));
    } else {
      await _box.delete(_kMasterKeyB64);
    }
  }

  Uint8List _deriveKeyWithPBKDF2({
    required Uint8List password,
    required Uint8List salt,
    required int iterationCount,
    required int keyLength,
  }) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    final params = Pbkdf2Parameters(salt, iterationCount, keyLength);
    derivator.init(params);
    return derivator.process(password);
  }

  /// ✅ 仅派生：用于 Verify，不写入 state、不落盘
  Uint8List deriveMasterKeyFromMnemonic(String mnemonicInput) {
    final mnemonic = mnemonicInput.trim().replaceAll(RegExp(r'\s+'), ' ');
    final saltBytes = utf8.encode(_appSaltString);

    return _deriveKeyWithPBKDF2(
      password: Uint8List.fromList(utf8.encode(mnemonic)),
      salt: Uint8List.fromList(saltBytes),
      iterationCount: 100000,
      keyLength: 32,
    );
  }

  Future<void> createMasterKeyFromMnemonic(List<String> words) async {
    final mnemonic = words.join(' ').trim();
    final saltBytes = utf8.encode(_appSaltString);

    _masterKey = _deriveKeyWithPBKDF2(
      password: Uint8List.fromList(utf8.encode(mnemonic)),
      salt: Uint8List.fromList(saltBytes),
      iterationCount: 100000,
      keyLength: 32,
    );

    state = state.copyWith(
      hasMnemonic: true,
      hasMasterKey: true,
      createdAt: DateTime.now(),
    );
    await _saveState();
  }

  Future<void> restoreMasterKeyFromMnemonic(String mnemonicInput) async {
    final mnemonic = mnemonicInput.trim().replaceAll(RegExp(r'\s+'), ' ');
    final saltBytes = utf8.encode(_appSaltString);

    _masterKey = _deriveKeyWithPBKDF2(
      password: Uint8List.fromList(utf8.encode(mnemonic)),
      salt: Uint8List.fromList(saltBytes),
      iterationCount: 100000,
      keyLength: 32,
    );

    state = state.copyWith(
      hasMnemonic: true,
      hasMasterKey: true,
      createdAt: state.createdAt ?? DateTime.now(),
    );
    await _saveState();
  }

  Future<void> clearMasterKey() async {
    _masterKey = null;
    state = state.copyWith(hasMasterKey: false);
    await _saveState();
  }

  Future<void> resetCryptoAll() async {
    _masterKey = null;
    state = CryptoState.initial();
    await _box.clear();
  }

  /// ====== Encrypt/Decrypt API for Notes ======

  String encryptTextToEnc(String plainText) {
    final k = _masterKey;
    if (k == null || k.length != 32) {
      throw StateError('No masterKey on this device');
    }
    final r = NoteCipher.encryptText(key32: k, plainText: plainText);
    return r.packCompact();
  }

  String decryptEncToText(String encCompact) {
    final k = _masterKey;
    if (k == null || k.length != 32) {
      throw StateError('No masterKey on this device');
    }
    return NoteCipher.decryptText(key32: k, encCompact: encCompact);
  }
}
