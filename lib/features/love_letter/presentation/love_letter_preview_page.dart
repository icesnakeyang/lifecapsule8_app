import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/app_theme.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';

import 'package:lifecapsule8_app/features/love_letter/application/love_letter_preview_controller.dart';

class LoveLetterPreviewPage extends ConsumerStatefulWidget {
  final String? noteId;
  const LoveLetterPreviewPage({super.key, this.noteId});

  @override
  ConsumerState<LoveLetterPreviewPage> createState() =>
      _LoveLetterPreviewPageState();
}

class _LoveLetterPreviewPageState extends ConsumerState<LoveLetterPreviewPage> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;

    final noteId = widget.noteId;
    if (noteId == null || noteId.trim().isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(loveLetterPreviewControllerProvider.notifier)
          .open(noteId: noteId);
    });
  }

  // ===== theme helpers (ONLY appThemeProvider) =====

  Color _cardBg(AppTheme theme) => Colors.white.withOpacity(0.08);
  Color _cardBorder(AppTheme theme) =>
      theme.loveLetter.onPrimary.withOpacity(0.18);
  Color _muted(AppTheme theme) => theme.loveLetter.onPrimary.withOpacity(0.70);
  Color _muted2(AppTheme theme) => theme.loveLetter.onPrimary.withOpacity(0.62);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(loveLetterPreviewControllerProvider);
    final s = async.value;

    final opening = s?.opening == true;
    final confirming = s?.confirming == true;
    final note = s?.note;

    final theme = ref.read(appThemeProvider);
    final palette = theme.loveLetter;
    final on = palette.onPrimary;

    return PopScope(
      canPop: !confirming,
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
            'Letter Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: on,
            ),
          ),
          iconTheme: IconThemeData(color: on),
          centerTitle: false,
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: opening
                  ? Center(child: CircularProgressIndicator(color: on))
                  : (note == null)
                  ? _ErrorCenter(message: s?.error ?? 'Letter not found')
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        if ((s?.error ?? '').isNotEmpty) ...[
                          _ErrorBanner(message: s!.error!),
                          const SizedBox(height: 12),
                        ],

                        // Summary card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _cardBg(theme),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _cardBorder(theme)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _RowIconText(
                                icon: Icons.person_rounded,
                                text: s!.toLine,
                                theme: theme,
                              ),
                              const SizedBox(height: 8),
                              _RowIconText(
                                icon: Icons.person_outline_rounded,
                                text: s.fromLine,
                                theme: theme,
                              ),
                              const SizedBox(height: 14),
                              _RowIconText(
                                icon: Icons.schedule_rounded,
                                text: 'Send mode: ${s.sendModeText}',
                                theme: theme,
                              ),
                              const SizedBox(height: 8),
                              _RowIconText(
                                icon: Icons.event_rounded,
                                text: 'Send at: ${s.sendAtText}',
                                theme: theme,
                              ),
                              const SizedBox(height: 14),
                              _RowIconText(
                                icon: Icons.lock_rounded,
                                text: 'Protection: ${s.protectionText}',
                                theme: theme,
                              ),
                              if (s.qaQuestion != null) ...[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.only(left: 28),
                                  child: Text(
                                    'Question: ${s.qaQuestion}',
                                    style: TextStyle(color: _muted2(theme)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Content card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _cardBg(theme),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _cardBorder(theme)),
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 160),
                            child: SelectableText(
                              (note.content ?? '').trim().isEmpty
                                  ? '(Empty letter)'
                                  : note.content!,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: on.withOpacity(0.92),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.disabled)) {
                                  return Colors.white.withOpacity(0.10);
                                }
                                return on.withOpacity(0.20);
                              }),
                              foregroundColor: WidgetStateProperty.all(on),
                              overlayColor: WidgetStateProperty.all(
                                on.withOpacity(0.10),
                              ),
                              elevation: WidgetStateProperty.all(0),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: on.withOpacity(0.28)),
                                ),
                              ),
                              textStyle: WidgetStateProperty.all(
                                const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            onPressed: confirming
                                ? null
                                : () async {
                                    await ref
                                        .read(
                                          loveLetterPreviewControllerProvider
                                              .notifier,
                                        )
                                        .confirmAndSend();

                                    final latest = ref
                                        .read(
                                          loveLetterPreviewControllerProvider,
                                        )
                                        .value;
                                    if (!context.mounted) return;

                                    if ((latest?.error ?? '').isEmpty) {
                                      Navigator.of(
                                        context,
                                      ).popUntil((r) => r.isFirst);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(latest!.error!),
                                          backgroundColor: theme.error,
                                        ),
                                      );
                                    }
                                  },
                            icon: confirming
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: on,
                                    ),
                                  )
                                : Icon(Icons.send_rounded, color: on),
                            label: Text(
                              confirming ? 'Confirming...' : 'Confirm & Send',
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        Text(
                          'After confirming, we will schedule the delivery based on your chosen time.',
                          style: TextStyle(color: _muted(theme), fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowIconText extends ConsumerWidget {
  const _RowIconText({
    required this.icon,
    required this.text,
    required this.theme,
  });

  final IconData icon;
  final String text;
  final AppTheme theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = theme.loveLetter.onPrimary;

    return Row(
      children: [
        Icon(icon, size: 18, color: on.withOpacity(0.75)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: on.withOpacity(0.92)),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(appThemeProvider);
    final on = theme.loveLetter.onPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.error.withOpacity(0.35)),
      ),
      child: Text(message, style: TextStyle(color: on.withOpacity(0.92))),
    );
  }
}

class _ErrorCenter extends ConsumerWidget {
  const _ErrorCenter({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(appThemeProvider);
    final on = theme.loveLetter.onPrimary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: on.withOpacity(0.70)),
        ),
      ),
    );
  }
}
