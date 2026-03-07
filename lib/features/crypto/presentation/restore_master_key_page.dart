import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/core/crypto/crypto_provider.dart';

class RestoreMasterKeyPage extends ConsumerStatefulWidget {
  const RestoreMasterKeyPage({super.key});

  @override
  ConsumerState<RestoreMasterKeyPage> createState() =>
      _RestoreMasterKeyPageState();
}

class _RestoreMasterKeyPageState extends ConsumerState<RestoreMasterKeyPage> {
  final _controller = TextEditingController();
  bool _loading = false;

  String _normalize(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  int _wordCount(String normalized) {
    if (normalized.isEmpty) return 0;
    return normalized.split(' ').where((w) => w.trim().isNotEmpty).length;
  }

  Future<void> _restore() async {
    if (_loading) return;

    final mnemonic = _normalize(_controller.text);
    final count = _wordCount(mnemonic);
    if (count != 12) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter exactly 12 words. (Current: $count)'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(cryptoProvider.notifier)
          .restoreMasterKeyFromMnemonic(mnemonic);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device unlocked successfully')),
      );
      Navigator.pop(context);
    } catch (_) {
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Unlock This Device',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Enter your 12-word mnemonic phrase to restore the local master key.\n'
              'This happens locally, nothing is uploaded.',
              style: TextStyle(fontSize: 15, height: 1.3),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'word1 word2 ... word12',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _restore,
                child: Text(_loading ? 'Restoring...' : 'Unlock'),
              ),
            ),
            SizedBox(height: bottomInset + 12),
          ],
        ),
      ),
    );
  }
}
