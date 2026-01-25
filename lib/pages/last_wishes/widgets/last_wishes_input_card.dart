// lib/pages/last_wishes/widgets/last_wishes_input_card.dart

import 'package:flutter/material.dart';

class LastWishesInputCard extends StatelessWidget {
  final String title;
  final String hint;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final int maxLines;

  const LastWishesInputCard({
    super.key,
    required this.title,
    required this.hint,
    required this.initialValue,
    required this.onChanged,
    this.maxLines = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF163B28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialValue,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF0E2A1C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
