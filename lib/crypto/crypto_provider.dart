// lib/core/crypto/crypto_provider.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import 'package:lifecapsule8_app/hive/hive_boxes.dart';
import 'package:pointycastle/export.dart';

import 'crypto_state.dart';

final cryptoProvider = StateNotifierProvider<CryptoNotifier, CryptoState>((
  ref,
) {
  return CryptoNotifier()..init();
});

class CryptoNotifier extends StateNotifier<CryptoState> {
  CryptoNotifier() : super(CryptoState.initial());

  late Box _box;

  /// 内存中的 masterKey，不落盘
  Uint8List? _masterKey;
  Uint8List? get masterKey => _masterKey;

  Future<void> init() async {
    _box = Hive.box(HiveBoxes.crypto);

    final hasMnemonic = (_box.get('hasMnemonic') as bool?) ?? false;
    final createdAtMs = _box.get('createdAtMs') as int?;
    final masterKeyB64 = _box.get('masterKeyB64') as String?;

    DateTime? createdAt;
    if (createdAtMs != null) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    }

    if (masterKeyB64 != null) {
      _masterKey = base64Decode(masterKeyB64);
    }

    state = CryptoState(
      hasMnemonic: hasMnemonic,
      hasMasterKey: _masterKey != null,
      createdAt: createdAt,
    );
  }

  Future<void> _saveState() async {
    await _box.put('hasMnemonic', state.hasMnemonic);
    if (state.createdAt != null) {
      await _box.put('createdAtMs', state.createdAt!.millisecondsSinceEpoch);
    } else {
      await _box.delete('createdAtMs');
    }
    if (_masterKey != null) {
      await _box.put('masterKeyB64', base64Encode(_masterKey!));
    } else {
      await _box.delete('masterKeyB64');
    }
  }

  /// 第一次生成助记词时调用：从 12 个词生成 masterKey
  Future<void> createMasterKeyFromMnemonic(List<String> words) async {
    final mnemonic = words.join(' ').trim();

    // 建议使用固定 salt（只和应用相关），防止直接从助记词→key 有结构性问题
    // 可以写死一个常量字符串，也可以后面放配置文件
    const appSaltString = 'LifeCapsule8_MnemonicRoot_v1';
    final saltBytes = utf8.encode(appSaltString);

    _masterKey = _deriveKeyWithPBKDF2(
      Uint8List.fromList(utf8.encode(mnemonic)),
      Uint8List.fromList(saltBytes),
      100000, // 迭代次数
      32, // 32 字节 = 256bit AES key
    );

    state = state.copyWith(
      hasMnemonic: true,
      hasMasterKey: true,
      createdAt: DateTime.now(),
    );
    await _saveState();
  }

  /// 从用户手动输入的助记词恢复 masterKey（新设备恢复用）
  Future<void> restoreMasterKeyFromMnemonic(String mnemonicInput) async {
    final mnemonic = mnemonicInput.trim().replaceAll(RegExp(r'\s+'), ' ');

    const appSaltString = 'LifeCapsule8_MnemonicRoot_v1';
    final saltBytes = utf8.encode(appSaltString);

    final key = _deriveKeyWithPBKDF2(
      Uint8List.fromList(utf8.encode(mnemonic)),
      Uint8List.fromList(saltBytes),
      100000,
      32,
    );

    _masterKey = key;
    state = state.copyWith(
      hasMnemonic: true, // 用户既然能输入对助记词，视为“有助记词”
      hasMasterKey: true,
      createdAt: state.createdAt ?? DateTime.now(),
    );
    await _saveState();
  }

  Uint8List _deriveKeyWithPBKDF2(
    Uint8List password,
    Uint8List salt,
    int iterationCount,
    int keyLength,
  ) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    final params = Pbkdf2Parameters(salt, iterationCount, keyLength);
    derivator.init(params);
    return derivator.process(password);
  }

  /// 清除本地 masterKey（例如用户登出）
  Future<void> clearMasterKey() async {
    _masterKey = null;
    state = state.copyWith(hasMasterKey: false);
    await _saveState();
  }

  // 清空所有数据，包括密钥和所有本地笔记，永远无法恢复
  Future<void> resetCryptoAll() async {
    _masterKey = null;
    state = CryptoState.initial();
    await _box.clear();
  }
}
