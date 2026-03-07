import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/crypto/application/mnemonic_restore_controller.dart';

class MnemonicRestorePage extends ConsumerWidget {
  const MnemonicRestorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncS = ref.watch(mnemonicRestoreControllerProvider);
    final ctl = ref.read(mnemonicRestoreControllerProvider.notifier);
    final s = asyncS.value;

    if (asyncS.isLoading || s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Restore Key',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (s.error != null && s.error!.trim().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              'Enter your 12-word mnemonic phrase (space separated).',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'word1 word2 ... word12',
              ),
              onChanged: ctl.setMnemonic,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: s.loading ? null : () => ctl.restore(context),
                child: Text(s.loading ? 'Restoring...' : 'Restore'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
