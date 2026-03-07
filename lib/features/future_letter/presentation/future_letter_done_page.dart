// lib/features/future_letter/presentation/future_letter_done_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/future_letter_route_paths.dart';
import 'package:lifecapsule8_app/features/home/home_route_paths.dart';

class FutureLetterDonePage extends ConsumerWidget {
  final String? noteId;
  final bool? success;
  final String? message;

  const FutureLetterDonePage({
    super.key,
    this.noteId,
    this.success,
    this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final palette = theme.future;

    // read args (optional)
    final args = ModalRoute.of(context)?.settings.arguments;
    String? argNoteId = noteId;
    bool? argSuccess = success;
    String? argMessage = message;

    if (args is Map) {
      final v1 = args['noteId'];
      final v2 = args['success'];
      final v3 = args['message'];
      if (argNoteId == null && v1 is String) argNoteId = v1;
      if (argSuccess == null && v2 is bool) argSuccess = v2;
      if (argMessage == null && v3 is String) argMessage = v3;
    }

    final isOk = argSuccess ?? true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Future letter',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: palette.onPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.gradientStart, palette.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ✅ Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: _ResultCard(
                            palette: palette,
                            isOk: isOk,
                            noteId: argNoteId,
                            message: argMessage,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        'Note: You can always edit and resend later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.onPrimary.withValues(alpha: 0.70),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // ✅ Fixed actions at bottom
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isOk) ...[
                              _PrimaryButton(
                                palette: palette,
                                icon: Icons.home_rounded,
                                label: 'Back to Home',
                                onPressed: () {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    HomeRoutePaths.home,
                                    (route) => false,
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _SecondaryButton(
                                palette: palette,
                                icon: Icons.edit_rounded,
                                label: 'View / Edit this letter',
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    FutureLetterRoutePaths.write,
                                    arguments: {'noteId': argNoteId},
                                  );
                                },
                              ),
                            ] else ...[
                              _PrimaryButton(
                                palette: palette,
                                icon: Icons.edit_rounded,
                                label: 'Back to Write',
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    FutureLetterRoutePaths.write,
                                    arguments: {'noteId': argNoteId},
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _SecondaryButton(
                                palette: palette,
                                icon: Icons.home_rounded,
                                label: 'Back to Home',
                                onPressed: () {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    HomeRoutePaths.home,
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final dynamic palette; // keep compatible with your palette type
  final bool isOk;
  final String? noteId;
  final String? message;

  const _ResultCard({
    required this.palette,
    required this.isOk,
    required this.noteId,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isOk ? Icons.check_circle_rounded : Icons.error_rounded;
    final title = isOk ? 'Sent successfully' : 'Send failed';
    final subtitle = isOk
        ? 'Your letter to the future has been scheduled / sent.'
        : 'We couldn’t send your letter. Please try again.';

    final detail = (message != null && message!.trim().isNotEmpty)
        ? message!.trim()
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 54,
            color: palette.onPrimary.withValues(alpha: 0.95),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.onPrimary.withValues(alpha: 0.95),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.onPrimary.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          if (noteId != null && noteId!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Note ID: $noteId',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.onPrimary.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
          if (detail != null) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    detail,
                    style: TextStyle(
                      color: palette.onPrimary.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final dynamic palette;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          foregroundColor: palette.onPrimary.withValues(alpha: 0.95),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1,
            ),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final dynamic palette;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.onPrimary.withValues(alpha: 0.92),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
