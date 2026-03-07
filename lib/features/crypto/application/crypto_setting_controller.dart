import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/core/crypto/crypto_provider.dart';

final cryptoSettingControllerProvider = Provider<CryptoSettingState>((ref) {
  final crypto = ref.watch(cryptoProvider);

  return CryptoSettingState(
    hasMnemonic: crypto.hasMnemonic,
    hasMasterKey: crypto.hasMasterKey,
    createdAt: crypto.createdAt,
  );
});

class CryptoSettingState {
  final bool hasMnemonic;
  final bool hasMasterKey;
  final DateTime? createdAt;

  const CryptoSettingState({
    required this.hasMnemonic,
    required this.hasMasterKey,
    required this.createdAt,
  });

  bool get isReady => hasMnemonic && hasMasterKey;

  /// 已创建助记词，但本机没有 masterKey（例如新装/清除本机 key）
  bool get isDeviceLocked => hasMnemonic && !hasMasterKey;
}
