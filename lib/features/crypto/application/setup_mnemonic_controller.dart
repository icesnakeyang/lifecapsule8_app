import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/core/crypto/crypto_provider.dart';
import 'package:lifecapsule8_app/core/crypto/mnemonic_util.dart';

final setupMnemonicControllerProvider =
    AsyncNotifierProvider.autoDispose<
      SetupMnemonicController,
      SetupMnemonicState
    >(SetupMnemonicController.new);

class SetupMnemonicState {
  final bool loading;
  final List<String> words;

  const SetupMnemonicState({this.loading = true, this.words = const []});

  SetupMnemonicState copyWith({bool? loading, List<String>? words}) {
    return SetupMnemonicState(
      loading: loading ?? this.loading,
      words: words ?? this.words,
    );
  }
}

class SetupMnemonicController extends AsyncNotifier<SetupMnemonicState> {
  @override
  Future<SetupMnemonicState> build() async {
    final words = MnemonicUtil.generate(wordCount: 12);
    return SetupMnemonicState(loading: false, words: words);
  }

  Future<void> confirmSaved() async {
    final s = state.value;
    if (s == null || s.loading) return;

    state = AsyncData(s.copyWith(loading: true));
    try {
      await ref
          .read(cryptoProvider.notifier)
          .createMasterKeyFromMnemonic(s.words);
    } finally {
      final latest = state.value ?? s;
      state = AsyncData(latest.copyWith(loading: false));
    }
  }
}
