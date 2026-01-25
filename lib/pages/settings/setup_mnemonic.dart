import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/crypto/crypto_provider.dart';
import 'package:lifecapsule8_app/crypto/mnemonic_util.dart';

class SetupMnemonicPage extends ConsumerStatefulWidget {
  const SetupMnemonicPage({super.key});

  @override
  ConsumerState<SetupMnemonicPage> createState() => _SetupMnemonicPageState();
}

class _SetupMnemonicPageState extends ConsumerState<SetupMnemonicPage> {
  late final List<String> _words;

  @override
  void initState() {
    super.initState();
    // Generate a new mnemonic phrase when entering the page
    _words = MnemonicUtil.generate(wordCount: 12);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Backup Mnemonic Phrase',
          style: TextStyle(fontSize: 14),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please carefully write down the following 12 words in order and store them securely.\n\n'
                'We do NOT store your mnemonic phrase.\n'
                'If it is lost, your notes can never be decrypted or recovered.',
                style: TextStyle(fontSize: 12, fontFamily: "Quicksand"),
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < _words.length; i++)
                    Chip(label: Text('${i + 1}. ${_words[i]}')),
                ],
              ),

              const SizedBox(height: 8),
              const Text(
                '⚠️ Security recommendations:\n'
                '• Write it down on paper or print it\n'
                '• Do NOT take screenshots\n'
                '• Do NOT store it in chat apps, email attachments, or online service',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontFamily: "Fredoka",
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // At this stage:
                    // - The mnemonic is used only to derive the local master key
                    // - It is NOT uploaded to the server
                    // - It is NOT stored in plaintext locally
                    await ref
                        .read(cryptoProvider.notifier)
                        .createMasterKeyFromMnemonic(_words);

                    if (!mounted) return;
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Mnemonic phrase created and used to generate your encryption key',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'I Have Written It Down Safely',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
