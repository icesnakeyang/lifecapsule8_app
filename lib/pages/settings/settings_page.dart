import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/crypto/crypto_provider.dart';
import 'package:lifecapsule8_app/provider/user/user_provider.dart';
import 'package:lifecapsule8_app/theme/theme_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1) Encryption status
    final crypto = ref.watch(cryptoProvider);
    final bool hasKey = crypto.hasMasterKey;

    // 2) Account binding status
    final userState = ref.watch(userProvider);
    final bool canSyncRestore = userState.isEmailBound;

    final needEncryption = !hasKey;
    final needAccountBind = !canSyncRestore;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _GuideCard(
              title: needEncryption
                  ? 'Encryption Not Enabled'
                  : 'Encryption Enabled',
              subtitle: needEncryption
                  ? 'Your note are currently stored without end-to-end encryption. '
                        'Set up your personal encryption key to protect them, '
                        'even if your account or device is compromised.'
                  : 'Your notes are encrypted before being synced. '
                        'Only you can decrypt them using your recovery phrase.',
              level: needEncryption ? _GuideLevel.danger : _GuideLevel.ok,
              actionText: needEncryption ? 'Enable Encryption' : 'Manage',
              onTap: () => Navigator.pushNamed(context, '/cryptosetting'),
              showDot: needEncryption,
            ),

            const SizedBox(height: 12),

            _GuideCard(
              title: needAccountBind ? 'Email Not Bound' : 'Email Bound',
              subtitle: needAccountBind
                  ? 'Your notes are only stored on this device. '
                        'If you reinstall the app or switch to a new device, '
                        'they cannot be recovered. '
                        'Bind your account to securely restore your notes on any device.'
                  : 'Your account is securely linked. You can sign in on a new device and sync your encrypted notes safely.',
              level: needAccountBind ? _GuideLevel.warn : _GuideLevel.ok,
              actionText: needAccountBind ? 'Bind Account' : 'Manage',
              onTap: () => Navigator.pushNamed(context, '/MyProfile'),
              showDot: needAccountBind,
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Other settings tiles
            // const ThemeSwitchTile(),
            // const LanguageSelectionTile(),
          ],
        ),
      ),
    );
  }
}

enum _GuideLevel { ok, warn, danger }

class _GuideCard extends ConsumerWidget {
  const _GuideCard({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onTap,
    required this.level,
    required this.showDot,
  });

  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onTap;
  final _GuideLevel level;
  final bool showDot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    Color border;
    Color dotColor;

    switch (level) {
      case _GuideLevel.ok:
        // border = const Color(0xff0A8A4C);
        border = theme.success;
        dotColor = theme.success;
        break;
      case _GuideLevel.warn:
        border = theme.warning;
        dotColor = theme.warning;
        break;
      case _GuideLevel.danger:
        border = theme.error;
        dotColor = theme.error;
        break;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          color: theme.surface,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status dot
            if (showDot)
              Container(
                margin: const EdgeInsets.only(top: 6, right: 10),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              )
            else
              const SizedBox(width: 20),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: level == _GuideLevel.ok
                          ? theme.success
                          : level == _GuideLevel.warn
                          ? theme.warning
                          : theme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: theme.onSurface)),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onTap,
                      child: Text(
                        actionText,
                        style: TextStyle(color: theme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
