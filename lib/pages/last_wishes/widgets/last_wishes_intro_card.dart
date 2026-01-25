// lib/pages/last_wishes/widgets/last_wishes_intro_card.dart

import 'package:flutter/material.dart';

class LastWishesIntroCard extends StatelessWidget {
  final String text;

  const LastWishesIntroCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF163B28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}
