// lib/core/crypto/crypto_state.dart
class CryptoState {
  final bool hasMnemonic;
  final bool hasMasterKey;
  final DateTime? createdAt;

  const CryptoState({
    required this.hasMnemonic,
    required this.hasMasterKey,
    this.createdAt,
  });

  factory CryptoState.initial() {
    return const CryptoState(
      hasMnemonic: false,
      hasMasterKey: false,
      createdAt: null,
    );
  }

  CryptoState copyWith({
    bool? hasMnemonic,
    bool? hasMasterKey,
    DateTime? createdAt,
  }) {
    return CryptoState(
      hasMnemonic: hasMnemonic ?? this.hasMnemonic,
      hasMasterKey: hasMasterKey ?? this.hasMasterKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
