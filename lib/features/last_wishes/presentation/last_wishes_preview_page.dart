import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/app/theme/app_theme.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/home/home_route_paths.dart';
import 'package:lifecapsule8_app/features/last_wishes/application/controllers/last_wishes_controller.dart';
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_route_paths.dart';

class LastWishesPreviewPage extends ConsumerStatefulWidget {
  final String? noteId;

  const LastWishesPreviewPage({super.key, this.noteId});

  @override
  ConsumerState<LastWishesPreviewPage> createState() =>
      _LastWishesPreviewPageState();
}

class _LastWishesPreviewPageState extends ConsumerState<LastWishesPreviewPage> {
  String? _resolvedNoteId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_resolvedNoteId != null) return;

    String? noteId = widget.noteId;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (noteId == null && args is Map) {
      noteId = args['noteId'] as String?;
    }

    _resolvedNoteId = (noteId == null || noteId.trim().isEmpty)
        ? 'last_wishes'
        : noteId.trim();
  }

  @override
  Widget build(BuildContext context) {
    final noteId = _resolvedNoteId ?? 'last_wishes';
    final asyncState = ref.watch(lastWishesControllerProvider(noteId));
    final notifier = ref.read(lastWishesControllerProvider(noteId).notifier);
    final theme = ref.read(appThemeProvider);
    final palette = theme.wishes;
    final on = palette.onPrimary;

    return asyncState.when(
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.gradientStart, palette.gradientEnd],
            ),
          ),
          child: SafeArea(
            child: Center(child: CircularProgressIndicator(color: on)),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Preview',
            style: TextStyle(
              color: on,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          iconTheme: IconThemeData(color: on),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.gradientStart, palette.gradientEnd],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Text(
                'Error: $e',
                style: TextStyle(color: on.withValues(alpha: 0.8)),
              ),
            ),
          ),
        ),
      ),
      data: (s) {
        final content = s.content.trim();
        final email = s.email.trim();
        final years = s.waitingYears;
        final note = s.messageNote.trim();
        final canConfirm = s.canConfirm;

        return PopScope(
          canPop: !s.submitting,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.of(context).pop(result);
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: Text(
                'Preview',
                style: TextStyle(
                  color: on,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              iconTheme: IconThemeData(color: on),
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: s.submitting ? null : () => Navigator.pop(context),
              ),
              actions: [
                if (s.enabled)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        HomeRoutePaths.home,
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Home',
                      style: TextStyle(
                        color: palette.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.gradientStart, palette.gradientEnd],
                ),
              ),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    if (s.error != null && s.error!.isNotEmpty) ...[
                      _ErrorBanner(message: s.error!, theme: theme),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Review before enabling delivery',
                      style: TextStyle(
                        color: on,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please double-check recipient and waiting period.',
                      style: TextStyle(
                        color: on.withValues(alpha: 0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Your Words',
                      icon: Icons.format_quote_rounded,
                      theme: theme,
                      child: _ReadOnlyBox(
                        text: content.isEmpty ? '(empty)' : content,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Recipient',
                      icon: Icons.alternate_email_rounded,
                      theme: theme,
                      child: _ReadOnlyRow(
                        label: 'Email',
                        value: email.isEmpty ? '-' : email,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Waiting Period',
                      icon: Icons.hourglass_bottom_rounded,
                      theme: theme,
                      child: _ReadOnlyRow(
                        label: 'We will wait',
                        value: years == null
                            ? '-'
                            : '$years year${years == 1 ? '' : 's'}',
                        theme: theme,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Message Note',
                      icon: Icons.sticky_note_2_rounded,
                      theme: theme,
                      child: _ReadOnlyBox(
                        text: note.isEmpty ? '-' : note,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoBox(theme: theme),
                    const SizedBox(height: 18),
                    if (!s.enabled) ...[
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: canConfirm
                                ? palette.accent
                                : palette.accent.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: FilledButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              shadowColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              overlayColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (!canConfirm) return Colors.transparent;
                                return on.withValues(alpha: 0.12);
                              }),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                            onPressed: canConfirm
                                ? () async {
                                    final ok = await notifier.confirmEnable();
                                    if (!context.mounted) return;

                                    if (ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text('Enabled.'),
                                          backgroundColor: palette.accent
                                              .withValues(alpha: 0.9),
                                        ),
                                      );

                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        LastWishesRoutePaths.done,
                                        (route) => false,
                                        arguments: {'noteId': noteId},
                                      );
                                    } else {
                                      final msg = ref
                                          .read(
                                            lastWishesControllerProvider(
                                              noteId,
                                            ),
                                          )
                                          .value
                                          ?.error;
                                      if (msg != null && msg.isNotEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(msg),
                                            backgroundColor: theme.error,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                            child: s.submitting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: on,
                                    ),
                                  )
                                : Text(
                                    'Confirm',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: canConfirm
                                          ? palette.onPrimary
                                          : palette.onPrimary.withValues(
                                              alpha: 0.5,
                                            ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You can always edit this later before it is delivered.',
                        style: TextStyle(
                          color: on.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: on.withValues(alpha: 0.16),
                            ),
                          ),
                          child: FilledButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              shadowColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              overlayColor: WidgetStateProperty.all(
                                on.withValues(alpha: 0.10),
                              ),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                            onPressed: s.submitting
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                      context,
                                      LastWishesRoutePaths.edit,
                                      arguments: {'noteId': noteId},
                                    );
                                  },
                            child: Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: on.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'This message is enabled. You can still edit it before delivery.',
                        style: TextStyle(
                          color: on.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final AppTheme theme;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final p = theme.wishes;
    final on = p.onPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: on.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: on.withValues(alpha: 0.75)),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: on,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ReadOnlyBox extends StatelessWidget {
  final String text;
  final AppTheme theme;

  const _ReadOnlyBox({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    final p = theme.wishes;
    final on = p.onPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: on.withValues(alpha: 0.14)),
      ),
      child: Text(
        text,
        style: TextStyle(
          height: 1.55,
          color: on.withValues(alpha: 0.92),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  final AppTheme theme;

  const _ReadOnlyRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final p = theme.wishes;
    final on = p.onPrimary;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: on.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: on.withValues(alpha: 0.92),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final AppTheme theme;
  const _InfoBox({required this.theme});

  @override
  Widget build(BuildContext context) {
    final p = theme.wishes;
    final on = p.onPrimary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: on.withValues(alpha: 0.14)),
      ),
      child: Text(
        'How delivery works:\n'
        '• When the waiting period ends, we will email you to ask whether to keep waiting.\n'
        '• If you do not respond within 30 days, your words will be delivered to your recipient.',
        style: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: on.withValues(alpha: 0.75),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final AppTheme theme;

  const _ErrorBanner({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    final p = theme.wishes;
    final on = p.onPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.error.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.error.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: on.withValues(alpha: 0.92),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
