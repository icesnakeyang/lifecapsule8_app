// lib/pages/last_wishes/last_wishes_destination_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/provider/last_wishes/last_wishes_provider.dart';
import 'package:lifecapsule8_app/provider/last_wishes/last_wishes_state.dart';

class LastWishesDestinationPage extends ConsumerWidget {
  const LastWishesDestinationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(lastWishesProvider);
    final notifier = ref.read(lastWishesProvider.notifier);

    final isPerson = s.destination == LastWishesDestination.person;

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
          'Destination',
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

              // To one person
              _ChoiceCard(
                title: 'To one person',
                desc:
                    'Someone you trust.\n'
                    'They will receive your words when the time comes.',
                icon: Icons.mail_outline,
                selected: isPerson,
                enabled: true,
                onTap: () =>
                    notifier.setDestination(LastWishesDestination.person),
              ),

              const SizedBox(height: 12),

              // To the world (coming later)
              _ChoiceCard(
                title: 'To the world (coming later)',
                desc:
                    'A public place for words meant to outlive you.\n'
                    'We will open this when we can protect it properly.',
                icon: Icons.public,
                selected: false,
                enabled: false, // disabled for now
              ),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
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
                      onPressed: () {
                        // 当前只允许 person，直接下一步
                        notifier.setDestination(LastWishesDestination.person);
                        notifier.next();

                        Navigator.pushNamed(
                          context,
                          '/LastWishesRecipientPage',
                        );
                      },
                      child: const Text('Continue'),
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
        'Where should these words go?\n'
        'Choose the path that feels right.',
        style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 14),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _ChoiceCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF163B28);
    final borderColor = selected ? const Color(0xFF4BE38A) : Colors.white24;

    Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: bg.withOpacity(enabled ? 1 : 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor.withOpacity(enabled ? 1 : 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: (enabled ? const Color(0xFF4BE38A) : Colors.white54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white60,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    color: enabled ? Colors.white70 : Colors.white54,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (enabled)
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? const Color(0xFF4BE38A) : Colors.white54,
            )
          else
            const Icon(Icons.lock_outline, color: Colors.white38),
        ],
      ),
    );

    if (!enabled) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
