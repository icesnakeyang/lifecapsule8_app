// lib/pages/last_wishes/last_wishes_view_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/last_wishes/last_wishes_provider.dart';
import 'package:lifecapsule8_app/provider/last_wishes/last_wishes_state.dart';
import 'package:lifecapsule8_app/theme/theme_provider.dart';

class LastWishesViewPage extends ConsumerWidget {
  const LastWishesViewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(lastWishesProvider);
    final notifier = ref.read(lastWishesProvider.notifier);
    final theme = ref.watch(themeProvider);

    final statusText = s.enabled ? 'Enabled' : 'Draft';

    return Scaffold(
      backgroundColor: const Color(0xFF0E2A1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2A1C),
        title: const Text(
          'Last Wishes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // content area
              Expanded(
                child: ListView(
                  children: [
                    _Card(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF163B28),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              'Status: $statusText',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            s.enabled ? Icons.verified : Icons.edit_note,
                            color: s.enabled
                                ? const Color(0xFF4BE38A)
                                : Colors.white54,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _Card(
                      title: 'Recipient',
                      child: Text(
                        s.recipientEmail ?? '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _Card(
                      title: 'Waiting period',
                      child: Text(
                        s.waitingYears == null
                            ? '-'
                            : '${s.waitingYears} years',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _Card(
                      title: 'Your words',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E2A1C),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          s.content.trim().isEmpty
                              ? '(Empty)'
                              : s.content.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // bottom actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                        // ✅ 进入编辑：把流程定位到 write
                        notifier.goTo(LastWishesStep.write);
                        Navigator.pushNamed(context, '/LastWishesWritePage');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.wishes,
                        foregroundColor: theme.onWishes,
                        disabledBackgroundColor: theme.wishes.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      child: const Text('Edit'),
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

class _Card extends StatelessWidget {
  final String? title;
  final Widget child;

  const _Card({this.title, required this.child});

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
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}
