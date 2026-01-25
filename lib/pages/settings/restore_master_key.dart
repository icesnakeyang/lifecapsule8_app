import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestoreMasterKey extends ConsumerStatefulWidget {
  const RestoreMasterKey({super.key});
  @override
  ConsumerState<RestoreMasterKey> createState() => _RestoreMasterKeyState();
}

class _RestoreMasterKeyState extends ConsumerState<RestoreMasterKey> {
  final controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restore Master Key', style: TextStyle(fontSize: 16)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Unlock This Device with Mnemonic',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Enter your 12-word mnemonic phrase (space separated) to regenerate the local unlock key.\n'
                        'This process happens locally and nothing is uploaded.',
                        style: TextStyle(fontSize: 12),
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
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(controller.text.trim()),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
