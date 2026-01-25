// lib/pages/last_wishes/last_wishes_done_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LastWishesDonePage extends ConsumerWidget {
  const LastWishesDonePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E2A1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2A1C),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Enabled',
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
              const Spacer(),
              _SuccessCard(
                onBackHome: () {
                  Navigator.pushNamed(context, '/');
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final VoidCallback onBackHome;

  const _SuccessCard({required this.onBackHome});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF163B28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: Color(0xFF4BE38A), size: 54),
          const SizedBox(height: 12),
          const Text(
            'Last Wishes enabled',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your words are safely stored.\n'
            'We will follow your instructions when the time comes.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onBackHome,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
