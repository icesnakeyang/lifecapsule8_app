import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/i18n/locale_provider.dart';
import 'package:lifecapsule8_app/core/utils/date_time_utils.dart';
import 'package:lifecapsule8_app/features/crypto/application/crypto_setting_controller.dart';
import 'package:lifecapsule8_app/features/crypto/crypto_route_paths.dart';

class CryptoSettingPage extends ConsumerWidget {
  const CryptoSettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(cryptoSettingControllerProvider);

    final hasMnemonic = st.hasMnemonic;
    final isDeviceLocked = st.isDeviceLocked;
    final isReady = st.isReady;

    late final String title;
    late final String desc;
    late final IconData icon;
    late final Color color;
    final locale = ref.watch(localeProvider).toString();

    if (!hasMnemonic) {
      title = 'Encryption Not Enabled';
      desc =
          'Your notes are currently stored only on this device.\n\n'
          'Enable end-to-end encryption to protect your notes before they ever leave your phone.\n'
          'We will generate a 12-word recovery phrase. Only this phrase can unlock your notes.\n\n'
          '⚠️ If you lose it, your encrypted notes cannot be recovered — not even by us.';
      icon = Icons.lock_open;
      color = Colors.orange;
    } else if (isDeviceLocked) {
      title = 'This Device Is Locked';
      desc =
          'You already created a 12-word recovery phrase, but this device doesn’t have the master key yet.\n\n'
          'Enter your phrase to unlock this device and decrypt your notes locally.\n'
          'Nothing is uploaded during this step.\n\n'
          'Tip: If the phrase is wrong, decryption will fail — your notes remain safe.';
      icon = Icons.lock_open;
      color = Colors.orange;
    } else {
      title = 'Encryption Enabled';
      desc =
          'Your notes are encrypted on this device before syncing.\n'
          'The server stores only encrypted ciphertext — it cannot read your content.\n\n'
          'Your 12-word recovery phrase is the ONLY key.\n'
          'Keep it offline. Never screenshot it. Never store it in chat/email/cloud.';
      icon = Icons.lock;
      color = Colors.green;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crypto',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          desc,
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        if (st.createdAt != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Created at: ${DateFormatter.dateTime(st.createdAt!, locale: locale)}',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (!hasMnemonic) ...[
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  CryptoRoutePaths.setupMnemonic,
                ),
                icon: const Icon(Icons.vpn_key),
                label: const Text('Generate 12-word Mnemonic'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  CryptoRoutePaths.setupMnemonic,
                ),
                child: const Text('Restore Existing Mnemonic'),
              ),
            ),
          ],

          if (isDeviceLocked) ...[
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  CryptoRoutePaths.restoreMasterKey,
                ),
                icon: const Icon(Icons.lock_reset),
                label: const Text('Unlock This Device'),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (isReady) ...[
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  CryptoRoutePaths.verifyMnemonic,
                ),
                label: Text(
                  'Verify Mnemonic',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  CryptoRoutePaths.setupMnemonic,
                ),
                label: Text(
                  'Replace Encryption Key',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
