import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/crypto/application/mnemonic_verify_controller.dart';

class MnemonicVerifyPage extends ConsumerWidget {
  const MnemonicVerifyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSt = ref.watch(mnemonicVerifyControllerProvider);
    final ctl = ref.watch(mnemonicVerifyControllerProvider.notifier);
    final st = asyncSt.value ?? const MnemonicVerifyState();

    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (st.ok == true) {
      statusColor = Colors.green;
      statusIcon = Icons.verified_rounded;
      statusText = 'Verified. This mnemonic matches your encryption key.';
    } else if (st.ok == false) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline_rounded;
      statusText = st.error ?? 'Not verified.';
    } else {
      statusColor = Colors.blueGrey;
      statusIcon = Icons.info_outline_rounded;
      statusText =
          'Verify Your Recovery Phrase\n\n'
          'Use this page to confirm that your 12-word recovery phrase '
          'correctly matches the encryption key stored on this device.\n\n'
          'This does NOT change your key.\n'
          'Nothing is uploaded.\n'
          'This is a local check only.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify Mnemonic',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          if (keyboardVisible)
            IconButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
              },
              icon: const Icon(Icons.keyboard_hide),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Enter your 12-words',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            TextField(
              maxLines: 3,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'word1 word2 ... word12',
              ),
              onChanged: ctl.setInput,
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.25)),
              ),
              child: const Text(
                'Tip:\n'
                '• Words are separated by spaces\n'
                '• Keep the original word order\n'
                '• Do not include commas or line breaks\n'
                '• This verification happens locally — nothing is uploaded',
                style: TextStyle(height: 1.35),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: st.verifying ? null : () => ctl.verify(),
                child: st.verifying
                    ? const SizedBox(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Verify',
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
