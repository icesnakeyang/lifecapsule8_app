// lib/pages/last_wishes/last_wishes_preview_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/provider/last_wishes/last_wishes_provider.dart';

class LastWishesPreviewPage extends ConsumerWidget {
  const LastWishesPreviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(lastWishesProvider);
    final notifier = ref.read(lastWishesProvider.notifier);

    final recipient = s.recipientEmail ?? '';
    final years = s.waitingYears ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0E2A1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2A1C),
        leading: BackButton(
          onPressed: () {
            notifier.back();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Preview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const _IntroCard(),
              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _SectionCard(
                        title: 'Your words',
                        child: _ReadOnlyBox(
                          text: s.content.trim().isEmpty
                              ? '(empty)'
                              : s.content.trim(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Recipient',
                        child: _ReadOnlyRow(
                          label: 'Email',
                          value: recipient.isEmpty ? '-' : recipient,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Waiting period',
                        child: _ReadOnlyRow(
                          label: 'We will wait',
                          value: years <= 0
                              ? '-'
                              : '$years year${years == 1 ? '' : 's'}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _RuleCard(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: s.submitting
                          ? null
                          : () {
                              notifier.back();
                              Navigator.pop(context);
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: s.submitting
                          ? null
                          : () async {
                              final ok = await notifier.confirmAndEnable();
                              if (!context.mounted) return;

                              if (ok) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/LastWishesDonePage',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Last Wishes enabled.'),
                                  ),
                                );
                              } else {
                                final msg = ref.read(lastWishesProvider).error;
                                if (msg != null && msg.isNotEmpty) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text(msg)));
                                }
                              }
                            },
                      child: s.submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Confirm',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),

              if (s.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  s.error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF163B28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: const Text(
        'Please review everything carefully.\n'
        'Once enabled, these words may be delivered in the future.',
        style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 14),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF163B28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: const Text(
        'How delivery works:\n'
        '• When the waiting period ends, we will email you to ask whether to keep waiting.\n'
        '• If you do not respond within 30 days, your words will be delivered to your recipient.',
        style: TextStyle(color: Colors.white60, height: 1.45, fontSize: 13),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF163B28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReadOnlyBox extends StatelessWidget {
  final String text;
  const _ReadOnlyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2A1C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 7,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
