import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/note/note_provider.dart';

class LoveLetterNext2 extends ConsumerStatefulWidget {
  const LoveLetterNext2({super.key});

  @override
  ConsumerState<LoveLetterNext2> createState() => _LoveLetterNext2State();
}

class _LoveLetterNext2State extends ConsumerState<LoveLetterNext2> {
  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goRecipient(String noteId) {
    Navigator.pushNamed(
      context,
      '/LoveLetterRecipient',
      arguments: {'noteId': noteId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = ref.watch(noteProvider).currentNote;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Love Letter Next',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF141B2D), Color(0xFF0C1224)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What would you like to do with this letter?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose how this letter should live.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 16),

                _ChoiceCard(
                  title: 'Keep it private',
                  subtitle: 'A letter only you will ever read',
                  icon: Icons.lock_outline,
                  onTap: _goHome,
                ),

                const SizedBox(height: 12),

                _ChoiceCard(
                  title: 'Send to someone',
                  subtitle: 'Let this letter reach someone in the future',
                  icon: Icons.send_rounded,
                  onTap: () {
                    final id = note?.id;
                    if (id == null) return;
                    _goRecipient(id);
                  },
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: _LetterPreviewCard(
                    content:
                        note?.content ?? 'This is the Love Letter Next 2 page.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2438),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.white70,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _LetterPreviewCard extends StatelessWidget {
  const _LetterPreviewCard({required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1729),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Text(
          content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ),
    );
  }
}
