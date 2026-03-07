import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/core/crypto/crypto_provider.dart';

final mnemonicRestoreControllerProvider =
    AsyncNotifierProvider.autoDispose<
      MnemonicRestoreController,
      MnemonicRestoreState
    >(MnemonicRestoreController.new);

class MnemonicRestoreState {
  final bool loading;
  final String mnemonic;
  final String? error;

  const MnemonicRestoreState({
    this.loading = false,
    this.mnemonic = '',
    this.error,
  });

  MnemonicRestoreState copyWith({
    bool? loading,
    String? mnemonic,
    String? error,
    bool clearError = false,
  }) {
    return MnemonicRestoreState(
      loading: loading ?? this.loading,
      mnemonic: mnemonic ?? this.mnemonic,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MnemonicRestoreController
    extends AsyncNotifier<MnemonicRestoreState> {
  @override
  Future<MnemonicRestoreState> build() async {
    return const MnemonicRestoreState();
  }

  void setMnemonic(String v) {
    final s = state.value ?? const MnemonicRestoreState();
    state = AsyncData(s.copyWith(mnemonic: v, clearError: true));
  }

  String normalize(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  int wordCount(String normalized) {
    if (normalized.isEmpty) return 0;
    return normalized.split(' ').where((w) => w.trim().isNotEmpty).length;
  }

  Future<bool> confirmReplaceIfAlreadyReady(BuildContext context) async {
    final crypto = ref.read(cryptoProvider);
    final alreadyReady = crypto.hasMnemonic && crypto.hasMasterKey;
    if (!alreadyReady) return true;

    final confirmCtl = TextEditingController();
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return AlertDialog(
              title: const Text(
                '⚠ Replace Existing Encryption Key',
                style: TextStyle(color: Colors.red),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This device is already protected.\n\n'
                    'If you restore a different mnemonic, existing encrypted notes may become unreadable.\n\n'
                    'Type REPLACE to continue.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtl,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'REPLACE',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    final t = confirmCtl.text.trim().toUpperCase();
                    Navigator.of(ctx).pop(t == 'REPLACE');
                  },
                  child: const Text('Confirm Replace'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> restore(BuildContext context) async {
    final s = state.value ?? const MnemonicRestoreState();
    if (s.loading) return;

    final mnemonic = normalize(s.mnemonic);
    final count = wordCount(mnemonic);

    if (count != 12) {
      state = AsyncData(
        s.copyWith(error: 'Please enter exactly 12 words. (Current: $count)'),
      );
      return;
    }

    final ok = await confirmReplaceIfAlreadyReady(context);
    if (!ok) return;

    state = AsyncData(s.copyWith(loading: true, clearError: true));
    try {
      await ref
          .read(cryptoProvider.notifier)
          .restoreMasterKeyFromMnemonic(mnemonic);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Encryption key restored successfully')),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      final latest = state.value ?? s;
      state = AsyncData(
        latest.copyWith(
          loading: false,
          error: 'Restore failed. Please check your mnemonic.',
        ),
      );
      return;
    }

    final latest = state.value ?? s;
    state = AsyncData(latest.copyWith(loading: false));
  }
}
