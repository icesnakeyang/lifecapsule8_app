// lib/core/crypto/note_cipher.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class NoteCipherResult {
  final String iv; // base64
  final String ciphertext; // base64（不含 tag）
  final String authTag; // base64（GCM tag）

  NoteCipherResult({
    required this.iv,
    required this.ciphertext,
    required this.authTag,
  });

  Map<String, dynamic> toJson() => {
    'iv': iv,
    'ciphertext': ciphertext,
    'authTag': authTag,
  };

  factory NoteCipherResult.fromJson(Map<String, dynamic> json) {
    return NoteCipherResult(
      iv: json['iv'] as String,
      ciphertext: json['ciphertext'] as String,
      authTag: json['authTag'] as String,
    );
  }

  /// 打包成一个字符串（适合存到 Hive 的一个字段里）
  String toCompactString() => jsonEncode(toJson());

  /// 从 compact string 还原
  static NoteCipherResult fromCompactString(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return NoteCipherResult.fromJson(map);
  }
}

class NoteCipher {
  static const int _ivLength = 12; // GCM 推荐 12 字节 IV
  static const int _tagLengthBits = 128; // 16 字节 tag

  /// 使用 AES-GCM 加密笔记正文
  static NoteCipherResult encrypt({
    required Uint8List masterKey,
    required String plaintext,
    Uint8List? aad, // 可选：额外认证数据
  }) {
    // 要求 key 长度为 16 / 24 / 32 字节（AES-128/192/256）
    assert(
      masterKey.length == 16 ||
          masterKey.length == 24 ||
          masterKey.length == 32,
      'masterKey length must be 16/24/32 bytes for AES',
    );

    // 1. 生成随机 IV
    final rnd = Random.secure();
    final iv = Uint8List(_ivLength);
    for (var i = 0; i < iv.length; i++) {
      iv[i] = rnd.nextInt(256);
    }

    // 2. 初始化 GCM cipher
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      true,
      AEADParameters(
        KeyParameter(masterKey),
        _tagLengthBits,
        iv,
        aad ?? Uint8List(0),
      ),
    );

    // 3. 加密
    final plainBytes = Uint8List.fromList(utf8.encode(plaintext));
    final out = cipher.process(plainBytes);

    // out = ciphertext + tag
    final tagLengthBytes = _tagLengthBits ~/ 8;
    final ctBytes = out.sublist(0, out.length - tagLengthBytes);
    final tagBytes = out.sublist(out.length - tagLengthBytes);

    return NoteCipherResult(
      iv: base64Encode(iv),
      ciphertext: base64Encode(ctBytes),
      authTag: base64Encode(tagBytes),
    );
  }

  /// 使用 AES-GCM 解密笔记正文
  static String decrypt({
    required Uint8List masterKey,
    required String ivB64,
    required String ciphertextB64,
    required String authTagB64,
    Uint8List? aad, // 必须与加密时保持一致（如果有的话）
  }) {
    assert(
      masterKey.length == 16 ||
          masterKey.length == 24 ||
          masterKey.length == 32,
      'masterKey length must be 16/24/32 bytes for AES',
    );

    final iv = base64Decode(ivB64);
    final ct = base64Decode(ciphertextB64);
    final tag = base64Decode(authTagB64);

    // 还原 GCM 需要的完整数据：ciphertext + tag
    final combined = Uint8List(ct.length + tag.length)
      ..setRange(0, ct.length, ct)
      ..setRange(ct.length, ct.length + tag.length, tag);

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      false,
      AEADParameters(
        KeyParameter(masterKey),
        _tagLengthBits,
        iv,
        aad ?? Uint8List(0),
      ),
    );

    final out = cipher.process(combined);
    return utf8.decode(out);
  }

  /// 一键加密为 compact string（适合直接存 Hive 的 String 字段）
  static String encryptToCompactString({
    required Uint8List masterKey,
    required String plaintext,
    Uint8List? aad,
  }) {
    final res = encrypt(masterKey: masterKey, plaintext: plaintext, aad: aad);
    return res.toCompactString();
  }

  /// 从 compact string 解密出明文
  static String decryptFromCompactString({
    required Uint8List masterKey,
    required String raw,
    Uint8List? aad,
  }) {
    final res = NoteCipherResult.fromCompactString(raw);
    return decrypt(
      masterKey: masterKey,
      ivB64: res.iv,
      ciphertextB64: res.ciphertext,
      authTagB64: res.authTag,
      aad: aad,
    );
  }

  /// 直接用 iv/ciphertext/tag 三段解密（你现在上传后端 parts 时就用这个）
  static String decryptFromParts({
    required Uint8List masterKey,
    required String ivB64,
    required String cipherTextB64,
    required String tagB64,
    Uint8List? aad,
  }) {
    return decrypt(
      masterKey: masterKey,
      ivB64: ivB64,
      ciphertextB64: cipherTextB64,
      authTagB64: tagB64,
      aad: aad,
    );
  }

  /// （可选）把 parts 合成 compact string，方便本地 Hive 仍然存一个字段
  static String packPartsToCompactString({
    required String ivB64,
    required String cipherTextB64,
    required String tagB64,
  }) {
    return NoteCipherResult(
      iv: ivB64,
      ciphertext: cipherTextB64,
      authTag: tagB64,
    ).toCompactString();
  }

  static NoteCipherParts unpackCompactString(String raw) {
    if (raw.isEmpty) {
      throw const FormatException('empty enc string');
    }

    // 1) ✅ 优先支持你当前的 JSON compact（最重要）
    try {
      final o = jsonDecode(raw) as Map<String, dynamic>;
      final iv = (o['iv'] as String?)?.trim();
      final ct = (o['ciphertext'] as String?)?.trim();
      final tag = (o['authTag'] as String?)?.trim();

      if (iv != null &&
          iv.isNotEmpty &&
          ct != null &&
          ct.isNotEmpty &&
          tag != null &&
          tag.isNotEmpty) {
        return NoteCipherParts(iv: iv, ciphertext: ct, authTag: tag);
      }
    } catch (_) {
      // continue to try colon format
    }

    // 2) 兼容 v1:iv:cipher:tag 或 iv:cipher:tag
    final parts = raw.startsWith('v1:')
        ? raw.substring(3).split(':')
        : raw.split(':');

    if (parts.length != 3) {
      throw FormatException(
        'invalid enc format: neither JSON nor 3-part compact, got ${parts.length} parts',
      );
    }

    final iv = parts[0].trim();
    final ciphertext = parts[1].trim();
    final authTag = parts[2].trim();

    if (iv.isEmpty || ciphertext.isEmpty || authTag.isEmpty) {
      throw const FormatException('invalid compact enc parts (empty field)');
    }

    return NoteCipherParts(iv: iv, ciphertext: ciphertext, authTag: authTag);
  }
}

class NoteCipherParts {
  final String iv; // base64
  final String ciphertext; // base64
  final String authTag; // base64

  const NoteCipherParts({
    required this.iv,
    required this.ciphertext,
    required this.authTag,
  });
}
