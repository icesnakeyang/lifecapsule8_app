import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/core/crypto/crypto_provider.dart';

final mnemonicVerifyControllerProvider =
    AsyncNotifierProvider.autoDispose<
      MnemonicVerifyController,
      MnemonicVerifyState
    >(MnemonicVerifyController.new);

class MnemonicVerifyState {
  final String input;
  final bool verifying;
  final bool? ok; // null=未验证, true/false=结果
  final String? error;

  const MnemonicVerifyState({
    this.input = '',
    this.verifying = false,
    this.ok,
    this.error,
  });

  MnemonicVerifyState copyWith({
    String? input,
    bool? verifying,
    bool? ok,
    String? error,
    bool clearOk = false,
    bool clearError = false,
  }) {
    return MnemonicVerifyState(
      input: input ?? this.input,
      verifying: verifying ?? this.verifying,
      ok: clearOk ? null : (ok ?? this.ok),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MnemonicVerifyController extends AsyncNotifier<MnemonicVerifyState> {
  @override
  MnemonicVerifyState build() => const MnemonicVerifyState();

  void setInput(String v) {
    final cur = state.value ?? const MnemonicVerifyState();
    state = AsyncData(cur.copyWith(input: v, clearError: true, clearOk: true));
  }

  String _normalize(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  int _countWords(String normalized) {
    if (normalized.isEmpty) return 0;
    return normalized.split(' ').where((w) => w.trim().isNotEmpty).length;
  }

  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.lengthInBytes != b.lengthInBytes) return false;
    for (int i = 0; i < a.lengthInBytes; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> verify() async {
    final cur = state.value ?? const MnemonicVerifyState();

    if (cur.verifying) return;
    final crypto = ref.read(cryptoProvider.notifier);
    final deviceKey = crypto.masterKey;

    if (deviceKey == null) {
      state = AsyncData(
        cur.copyWith(
          ok: false,
          error: 'This device is locked. Please unlock this device first.',
        ),
      );
      return;
    }

    final normalized = _normalize(cur.input);
    final wc = _countWords(normalized);
    if (wc != 12) {
      state = AsyncData(
        cur.copyWith(
          ok: false,
          error: 'Please enter exactly 12 words. (Current: $wc)',
        ),
      );
      return;
    }

    state = AsyncData(
      cur.copyWith(verifying: true, clearError: true, clearOk: true),
    );
    try {
      // ✅ 只派生，不写入，不保存
      final derived = crypto.deriveMasterKeyFromMnemonic(normalized);

      final ok = _bytesEqual(derived, deviceKey);
      final latest = state.value ?? cur;
      state = AsyncData(
        latest.copyWith(
          verifying: false,
          ok: ok,
          error: ok
              ? null
              : 'Verification failed.\n'
                    'This recovery phrase does not match the encryption key '
                    'stored on this device.\n'
                    'Please check the spelling and word order carefully.',
        ),
      );
    } catch (_) {
      final latest = state.value ?? cur;
      state = AsyncData(
        latest.copyWith(
          verifying: false,
          ok: false,
          error: 'Verification failed. Please check your words.',
        ),
      );
    }
  }
}
