import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/future/future_letter_provider.dart';

class FutureLetterRecipientPage extends ConsumerStatefulWidget {
  const FutureLetterRecipientPage({super.key});

  @override
  ConsumerState<FutureLetterRecipientPage> createState() =>
      _FutureLetterRecipientPageState();
}

class _FutureLetterRecipientPageState
    extends ConsumerState<FutureLetterRecipientPage> {
  final _emailCtrl = TextEditingController();
  final _userCodeCtrl = TextEditingController();
  final _toNameCtrl = TextEditingController();
  final _fromNameCtrl = TextEditingController();

  bool _inited = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _userCodeCtrl.dispose();
    _toNameCtrl.dispose();
    _fromNameCtrl.dispose();
    super.dispose();
  }

  void _initOnce() {
    if (_inited) return;
    _inited = true;

    final d = ref.read(futureLetterProvider).currentFutureLetter;
    if (d == null) {
      Future.microtask(() {
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    _emailCtrl.text = d.email ?? '';
    _userCodeCtrl.text = d.userCode ?? '';
    _toNameCtrl.text = d.toName ?? '';
    _fromNameCtrl.text = d.fromName ?? '';

    if (mounted) setState(() {});
  }

  bool get _canNext =>
      _emailCtrl.text.trim().isNotEmpty || _userCodeCtrl.text.trim().isNotEmpty;

  Future<void> _persistBeforeLeave() async {
    final notifier = ref.read(futureLetterProvider.notifier);

    await notifier.setRecipientInMemory(
      userCode: _userCodeCtrl.text.trim().isEmpty
          ? null
          : _userCodeCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      toName: _toNameCtrl.text.trim().isEmpty ? null : _toNameCtrl.text.trim(),
      fromName: _fromNameCtrl.text.trim().isEmpty
          ? null
          : _fromNameCtrl.text.trim(),
    );

    await notifier.persistCurrentIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    _initOnce();

    final d = ref.watch(futureLetterProvider).currentFutureLetter;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _persistBeforeLeave();
        if (!context.mounted) return;
        Navigator.of(context).pop(result);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Recipient',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _persistBeforeLeave();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        ),
        body: d == null
            ? const Center(child: Text('No letter selected'))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _userCodeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'User code (optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. LC-123456',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                        border: OutlineInputBorder(),
                        hintText: 'name@example.com',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can fill either one — or both. We’ll decide delivery on the server.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _toNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'To name (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fromNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'From name (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await _persistBeforeLeave();
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            },
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _canNext
                                ? () async {
                                    await _persistBeforeLeave();
                                    if (!context.mounted) return;
                                    Navigator.pushNamed(
                                      context,
                                      '/FutureLetterPreviewPage',
                                    );
                                  }
                                : null,
                            child: const Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
