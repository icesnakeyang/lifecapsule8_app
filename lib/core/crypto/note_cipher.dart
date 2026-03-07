import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class NoteCipherResult {
  final String ivB64; // 12 bytes
  final String ctB64; // ciphertext
  final String tagB64; // 16 bytes (128-bit)

  const NoteCipherResult({
    required this.ivB64,
    required this.ctB64,
    required this.tagB64,
  });

  Map<String, dynamic> toJson() => {'iv': ivB64, 'ct': ctB64, 'tag': tagB64};

  factory NoteCipherResult.fromJson(Map<String, dynamic> m) {
    return NoteCipherResult(
      ivB64: (m['iv'] ?? '').toString(),
      ctB64: (m['ct'] ?? '').toString(),
      tagB64: (m['tag'] ?? '').toString(),
    );
  }

  /// compact json string for storage/sync
  String packCompact() => jsonEncode(toJson());

  static NoteCipherResult unpackCompact(String raw) {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return NoteCipherResult.fromJson(m);
  }
}

class NoteCipher {
  static const int _ivLen = 12; // recommended for GCM
  static const int _tagBits = 128;

  static Uint8List _randomBytes(int n) {
    final r = Random.secure();
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = r.nextInt(256);
    }
    return out;
  }

  static NoteCipherResult encryptText({
    required Uint8List key32,
    required String plainText,
  }) {
    if (key32.length != 32) {
      throw ArgumentError('AES key must be 32 bytes (256-bit)');
    }

    final iv = _randomBytes(_ivLen);
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key32),
      _tagBits,
      iv,
      Uint8List(0),
    );
    cipher.init(true, params);

    final pt = Uint8List.fromList(utf8.encode(plainText));
    final out = cipher.process(pt);

    // pointycastle returns ct||tag
    final ct = out.sublist(0, out.length - 16);
    final tag = out.sublist(out.length - 16);

    return NoteCipherResult(
      ivB64: base64Encode(iv),
      ctB64: base64Encode(ct),
      tagB64: base64Encode(tag),
    );
  }

  static String decryptText({
    required Uint8List key32,
    required String encCompact,
  }) {
    if (key32.length != 32) {
      throw ArgumentError('AES key must be 32 bytes (256-bit)');
    }

    final r = NoteCipherResult.unpackCompact(encCompact);
    final iv = base64Decode(r.ivB64);
    final ct = base64Decode(r.ctB64);
    final tag = base64Decode(r.tagB64);

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key32),
      _tagBits,
      iv,
      Uint8List(0),
    );
    cipher.init(false, params);

    final combined = Uint8List(ct.length + tag.length)
      ..setRange(0, ct.length, ct)
      ..setRange(ct.length, ct.length + tag.length, tag);

    final pt = cipher.process(combined);
    return utf8.decode(pt);
  }
}
