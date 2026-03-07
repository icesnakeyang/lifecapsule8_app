import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/app/theme/app_theme.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/core/crypto/crypto_provider.dart';

// 暂时沿用你现有 provider（后续我们再重构到 core/）

// 模块路由 paths
import 'package:lifecapsule8_app/features/crypto/crypto_route_paths.dart';
import 'package:lifecapsule8_app/features/profile/profile_route_paths.dart';
import 'package:lifecapsule8_app/features/user/application/user_store.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppTheme theme = ref.watch(appThemeProvider);

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
              theme: theme,
              title: needEncryption
                  ? 'Encryption Not Enabled'
                  : 'Encryption Enabled',
              subtitle: needEncryption
                  ? 'Your notes are currently stored without end-to-end encryption. '
                        'Set up your personal recovery phrase to protect them — even if your device is compromised.'
                  : 'Your notes are encrypted before sync. Only you can decrypt them using your recovery phrase.',
              level: needEncryption ? _GuideLevel.danger : _GuideLevel.ok,
              actionText: needEncryption ? 'Enable Encryption' : 'Manage',
              onTap: () =>
                  Navigator.pushNamed(context, CryptoRoutePaths.manage),
              showDot: needEncryption,
            ),
            const SizedBox(height: 12),
            _GuideCard(
              theme: theme,
              title: needAccountBind ? 'Email Not Bound' : 'Email Bound',
              subtitle: needAccountBind
                  ? 'Your notes are only stored on this device. '
                        'If you reinstall or switch devices, they cannot be recovered. '
                        'Bind an email to restore your encrypted notes safely.'
                  : 'Your account is linked. You can sign in on another device and restore safely.',
              level: needAccountBind ? _GuideLevel.warn : _GuideLevel.ok,
              actionText: needAccountBind ? 'Bind Account' : 'Manage',
              onTap: () =>
                  Navigator.pushNamed(context, ProfileRoutePaths.profile),
              showDot: needAccountBind,
            ),
            const SizedBox(height: 16),
            Divider(color: theme.outline.withOpacity(0.35)),
            // 你后面要加 Theme/Language 等，建议也做成模块化 tile
          ],
        ),
      ),
    );
  }
}

enum _GuideLevel { ok, warn, danger }

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onTap,
    required this.level,
    required this.showDot,
  });

  final AppTheme theme;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onTap;
  final _GuideLevel level;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final Color border;
    final Color dotColor;
    final Color titleColor;

    switch (level) {
      case _GuideLevel.ok:
        border = theme.success;
        dotColor = theme.success;
        titleColor = theme.success;
        break;
      case _GuideLevel.warn:
        border = theme.warning;
        dotColor = theme.warning;
        titleColor = theme.warning;
        break;
      case _GuideLevel.danger:
        border = theme.error;
        dotColor = theme.error;
        titleColor = theme.error;
        break;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border.withOpacity(0.9)),
          color: theme.surfaceContainer,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.onSurface.withOpacity(0.82),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onTap,
                      child: Text(
                        actionText,
                        style: TextStyle(
                          color: theme.primary,
                          fontWeight: FontWeight.w600,
                        ),
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
