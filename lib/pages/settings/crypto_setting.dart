import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/crypto/crypto_provider.dart';
import 'package:lifecapsule8_app/provider/user/user_provider.dart';

class CryptoSetting extends ConsumerStatefulWidget {
  const CryptoSetting({super.key});

  @override
  ConsumerState<CryptoSetting> createState() => _CryptoSettingState();
}

class _CryptoSettingState extends ConsumerState<CryptoSetting> {
  Future<bool> _confirmDanger(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return AlertDialog(
              title: const Text(
                '⚠ Reset Private Key (Danger)',
                style: TextStyle(color: Colors.red),
              ),
              content: const Text(
                'This action will remove the local encryption key and crypto configuration on this device.\n\n'
                'Note: Encrypted notes stored in the cloud will NOT be deleted.\n'
                'If you have lost your mnemonic phrase, those notes will become permanently unreadable.\n\n'
                'Do you want to continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Confirm Reset'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// 二次确认：当当前已加密可用(isReady)时，恢复不同助记词可能导致现有笔记永久不可解密
  Future<bool> _confirmReplaceKeyIfAlreadyProtected() async {
    final confirmCtl = TextEditingController();

    final ok =
        await showDialog<bool>(
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
                    'This device is already protected by an encryption key.\n\n'
                    'If the mnemonic phrase you enter is different from the current one:\n'
                    '• Your existing encrypted notes may become permanently unreadable\n'
                    '• This action cannot be undone\n\n'
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

    return ok;
  }

  /// 全局：输入助记词恢复密钥（任何状态都可用）
  /// - 若当前已加密可用(isReady)，必须二次确认，避免误替换导致旧数据不可解密
  Future<void> _restoreKeyGlobal({required bool isReady}) async {
    final controller = TextEditingController();

    final mnemonic = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Restore Private Key with Mnemonic'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your 12-word mnemonic phrase (space separated) to restore your encryption key.\n'
                  'This process happens locally and nothing is uploaded.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'word1 word2 word3 ...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (mnemonic == null || mnemonic.trim().isEmpty) return;

    // 如果当前已经是“加密可用状态”，恢复可能会替换掉当前key → 强制二次确认
    if (isReady) {
      final ok = await _confirmReplaceKeyIfAlreadyProtected();
      if (!ok) return;
    }

    await ref
        .read(cryptoProvider.notifier)
        .restoreMasterKeyFromMnemonic(mnemonic);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Encryption key restored successfully')),
    );
  }

  /// 本机锁定态：输入助记词解锁（你原来的逻辑保留）
  Future<void> _restoreMasterKeyWithMnemonic() async {
    final controller = TextEditingController();

    final mnemonic = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Unlock This Device with Mnemonic'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your 12-word mnemonic phrase (space separated) to regenerate the local unlock key.\n'
                  'This process happens locally and nothing is uploaded.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'word1 word2 word3 ...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (mnemonic == null || mnemonic.trim().isEmpty) return;

    await ref
        .read(cryptoProvider.notifier)
        .restoreMasterKeyFromMnemonic(mnemonic);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local unlock key restored successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crypto = ref.watch(cryptoProvider);

    final bool hasMnemonic = crypto.hasMnemonic;
    final bool hasMasterKey = crypto.hasMasterKey;

    final bool isReady = hasMnemonic && hasMasterKey;
    final bool needRestoreOnThisDevice = hasMnemonic && !hasMasterKey;

    // 账户信息目前没用于 Crypto UI（保留读取不影响）
    final userState = ref.watch(userProvider);
    final boundEmail = userState.currentUser?.boundEmail;
    final hasBoundEmail = (boundEmail ?? '').trim().isNotEmpty;

    String statusTitle;
    String statusDesc;
    IconData statusIcon;
    Color statusColor;

    if (!hasMnemonic) {
      statusTitle = 'Encryption Not Enabled';
      statusDesc =
          'Your notes are currently not protected by end-to-end encryption.\n'
          'Enable encryption to protect your notes before syncing to the cloud.';
      statusIcon = Icons.lock_open;
      statusColor = Colors.orange;
    } else if (needRestoreOnThisDevice) {
      statusTitle = 'This Device Is Locked';
      statusDesc =
          'You have already created a mnemonic phrase, but this device is not unlocked.\n'
          'Enter your mnemonic phrase to regenerate the local unlock key and access your notes.';
      statusIcon = Icons.lock_open;
      statusColor = Colors.orange;
    } else {
      statusTitle = 'End-to-End Encryption Enabled';
      statusDesc =
          'Your notes are encrypted locally before syncing to the cloud.\n'
          'The server cannot read your data — only your mnemonic can unlock it.';
      statusIcon = Icons.lock;
      statusColor = Colors.green;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto', style: TextStyle(fontSize: 12)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          statusTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusDesc,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            /// Step 1: Enable encryption (only when not protected)
            if (!hasMnemonic) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enable End-to-End Encryption',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'We will generate 12 English words for you.\n'
                        'These words are the only way to generate your private encryption key.\n'
                        'If you lose them, your data cannot be recovered.\n\n'
                        'We do not store these words and cannot recover them for you.\n'
                        'Please write them down or store them offline.\n'
                        'Do NOT take screenshots, upload them to cloud storage, or share them with anyone.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/setupMnemonic'),
                          icon: const Icon(Icons.vpn_key),
                          label: const Text(
                            'Enable Encryption (Generate Mnemonic)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            /// Step 2: Unlock this device (only when mnemonic exists but local key missing)
            if (needRestoreOnThisDevice) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Step 2 · Unlock This Device',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You already have a mnemonic phrase.\n'
                        'Enter it to regenerate the local unlock key and decrypt your notes on this device.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _restoreMasterKeyWithMnemonic,
                          icon: const Icon(Icons.lock_reset),
                          label: const Text('Enter Mnemonic to Unlock'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            const Divider(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  /// Global restore key (always available)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => {
                        Navigator.pushNamed(context, '/MnemonicRestore'),
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text(
                        'Restore Existing Key (Enter Mnemonic)',
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
