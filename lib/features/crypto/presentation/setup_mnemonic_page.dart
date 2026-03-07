import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/crypto/application/setup_mnemonic_controller.dart';

class SetupMnemonicPage extends ConsumerWidget {
  const SetupMnemonicPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncS = ref.watch(setupMnemonicControllerProvider);
    final ctl = ref.read(setupMnemonicControllerProvider.notifier);
    final s = asyncS.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Backup Mnemonic Phrase',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: asyncS.isLoading || s == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const Text(
                    'These 12 words are your recovery phrase.\n\n'
                    'They are the ONLY way to restore access '
                    'to your encrypted notes.\n\n'
                    'LifeCapsule does NOT store this phrase. '
                    'If you lose it, your encrypted notes '
                    'cannot be recovered — not even by us.',
                    style: TextStyle(fontSize: 15, height: 1),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 1,
                    runSpacing: 1,
                    children: [
                      for (int i = 0; i < s.words.length; i++)
                        Chip(
                          label: Text(
                            '${i + 1}. ${s.words[i]}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    '⚠ Security guidelines:\n'
                    '• Write it down on paper and store it safely\n'
                    '• Do NOT take screenshots\n'
                    '• Do NOT save it in chat/email/cloud\n'
                    '• Keep it offline and private',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: s.loading
                          ? null
                          : () async {
                              await ctl.confirmSaved();
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Encryption enabled on this device',
                                  ),
                                ),
                              );
                            },
                      child: Text(
                        s.loading
                            ? 'Saving...'
                            : 'I Have Written It Down Safely',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
