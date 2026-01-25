import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/crypto/crypto_provider.dart';

class MnemonicRestorePage extends ConsumerStatefulWidget {
  const MnemonicRestorePage({super.key});

  @override
  ConsumerState<MnemonicRestorePage> createState() =>
      _MnemonicRestorePageState();
}

class _MnemonicRestorePageState extends ConsumerState<MnemonicRestorePage> {
  final _controller = TextEditingController();
  bool _loading = false;

  String _normalizeMnemonic(String raw) {
    // 去掉首尾空白 + 多空格合一
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  int _wordCount(String normalized) {
    if (normalized.isEmpty) return 0;
    return normalized.split(' ').where((w) => w.trim().isNotEmpty).length;
  }

  Future<bool> _confirmReplaceIfProtected() async {
    final confirmCtl = TextEditingController();

    final ok =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            final w = MediaQuery.of(ctx).size.width;
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: w,
                padding: const EdgeInsets.all(20),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠ Replace Existing Encryption Key',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This device is already protected by an encryption key.\n\n'
                      'If the mnemonic phrase you enter is different from the current one:\n'
                      '• Your existing encrypted notes may become permanently unreadable\n'
                      '• This action cannot be undone\n\n'
                      'Type REPLACE to continue.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmCtl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'REPLACE',
                        hintStyle: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            final t = confirmCtl.text.trim().toUpperCase();
                            Navigator.of(ctx).pop(t == 'REPLACE');
                          },
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;

    return ok;
  }

  Future<void> _restore() async {
    if (_loading) return;

    final crypto = ref.read(cryptoProvider);
    final isReady = crypto.hasMnemonic && crypto.hasMasterKey;

    final mnemonic = _normalizeMnemonic(_controller.text);
    final count = _wordCount(mnemonic);

    if (count != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter exactly 12 words. (Current: $count)'),
        ),
      );
      return;
    }

    // 如果当前已加密可用，恢复可能替换 key → 必须二次确认
    if (isReady) {
      final ok = await _confirmReplaceIfProtected();
      if (!ok) return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(cryptoProvider.notifier)
          .restoreMasterKeyFromMnemonic(mnemonic);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encryption key restored successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restore failed. Please check your mnemonic.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crypto = ref.watch(cryptoProvider);
    final isReady = crypto.hasMnemonic && crypto.hasMasterKey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restore Key', style: TextStyle(fontSize: 14)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isReady) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This device is already encrypted.\nRestoring a different mnemonic may make existing notes unreadable.',
                          style: TextStyle(fontSize: 14, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                Text(
                  'Enter your 12-word mnemonic phrase to restore your encryption key on this device.',
                  style: const TextStyle(fontSize: 12),
                ),
              const SizedBox(height: 12),

              TextField(
                controller: _controller,
                maxLines: 3,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'word1 word2 word3 ... word12',
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _restore,
                  child: Text(_loading ? 'Restoring...' : 'Restore'),
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                'Tip: Words are separated by spaces. Do not include commas or line breaks.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
