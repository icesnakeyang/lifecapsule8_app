// lib/pages/last_wishes/last_wishes_intro_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/provider/last_wishes/last_wishes_provider.dart';
import 'package:lifecapsule8_app/provider/last_wishes/last_wishes_state.dart';
import 'package:lifecapsule8_app/theme/theme_provider.dart';

class LastWishesIntroPage extends ConsumerWidget {
  const LastWishesIntroPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(lastWishesProvider);
    final theme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 12, 37, 25),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 12, 37, 25),
        leading: const BackButton(),
        title: const Text(
          'Last Wishes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: const [
                      _IntroCard(),
                      SizedBox(height: 12),
                      _HintCard(),
                    ],
                  ),
                ),
              ),

              // bottom button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.wishes,
                    foregroundColor: theme.onWishes,
                    disabledBackgroundColor: theme.wishes.withValues(
                      alpha: 0.35,
                    ),
                  ),
                  onPressed: () {
                    ref
                        .read(lastWishesProvider.notifier)
                        .goTo(LastWishesStep.write);

                    Navigator.pushNamed(context, '/LastWishesWritePage');
                  },
                  child: const Text('Continue'),
                ),
              ),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 18, 47, 32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before you write…',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'This is not a note for today.\n'
            'It is something you leave behind when you can no longer speak for yourself.\n\n'
            'Take a quiet moment. Think about what truly matters.',
            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 18, 47, 32),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Tip: You can edit your words anytime before they are released.',
        style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
      ),
    );
  }
}
