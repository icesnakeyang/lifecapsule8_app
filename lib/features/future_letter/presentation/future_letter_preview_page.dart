import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/app_theme.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/appication/future_letter_draft_store.dart';
import 'package:lifecapsule8_app/features/future_letter/appication/future_letter_preview_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/future_letter_route_paths.dart';

class FutureLetterPreviewPage extends ConsumerWidget {
  final String noteId;
  const FutureLetterPreviewPage({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final palette = theme.future;
    final asyncS = ref.watch(futureLetterPreviewControllerProvider);
    final controller = ref.read(futureLetterPreviewControllerProvider.notifier);

    final s = asyncS.value;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await controller.persistBeforeLeave();
        if (context.mounted) Navigator.of(context).pop(result);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Preview',
            style: TextStyle(
              color: palette.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: palette.onPrimary),
            onPressed: () async {
              await controller.persistBeforeLeave();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          centerTitle: false,
          actions: [],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [palette.gradientStart, palette.gradientEnd],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: asyncS.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if ((s?.error ?? '').trim().isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: theme.error.withValues(
                                        alpha: 0.85,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: theme.onError.withValues(
                                          alpha: 0.22,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: theme.onError,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            s!.error!,
                                            style: TextStyle(
                                              color: theme.onError,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                // 主卡片
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: palette.accent.withValues(
                                      alpha: 0.3,
                                    ),
                                    border: Border.all(
                                      color: palette.onPrimary.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                        color: Colors.black.withValues(
                                          alpha: 0.18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Final check',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Make sure everything looks right before sending.',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      const SizedBox(height: 12),

                                      _InfoRow(
                                        icon: Icons.schedule_rounded,
                                        title: 'Schedule',
                                        value: s?.scheduleText ?? '-',
                                        theme: theme,
                                      ),
                                      const SizedBox(height: 10),
                                      _InfoRow(
                                        icon: Icons.alternate_email_rounded,
                                        title: 'Recipient',
                                        value: s?.recipientText ?? '-',
                                        theme: theme,
                                      ),
                                      const SizedBox(height: 10),
                                      _InfoRow(
                                        icon: Icons.badge_outlined,
                                        title: 'Names',
                                        value: s?.namesText ?? '-',
                                        theme: theme,
                                      ),

                                      const SizedBox(height: 16),
                                      const Divider(
                                        height: 1,
                                        color: Colors.white24,
                                      ),
                                      const SizedBox(height: 16),

                                      const _SectionTitle(title: 'Content'),
                                      const SizedBox(height: 10),

                                      Container(
                                        constraints: const BoxConstraints(
                                          minHeight: 140,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          color: Colors.black.withValues(
                                            alpha: 0.12,
                                          ),
                                          border: Border.all(
                                            color: theme.future.onPrimary
                                                .withValues(alpha: 0.10),
                                          ),
                                        ),
                                        child:
                                            (s?.contentText ?? '')
                                                .trim()
                                                .isEmpty
                                            ? Text(
                                                'No content yet.',
                                                style: TextStyle(
                                                  color: theme.future.onPrimary
                                                      .withValues(alpha: 0.55),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              )
                                            : SelectableText(
                                                s!.contentText,
                                                style: TextStyle(
                                                  color: theme.future.onPrimary,
                                                  height: 1.55,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // 轻提示
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white.withValues(alpha: 0.06),
                                    border: Border.all(
                                      color: theme.future.onPrimary.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 18,
                                        color: theme.future.onPrimary
                                            .withValues(alpha: 0.65),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Your letter stays private. You can still go back and edit before confirming.',
                                          style: TextStyle(
                                            color: theme.future.onPrimary
                                                .withValues(alpha: 0.72),
                                            fontWeight: FontWeight.w600,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                SizedBox(
                                  height: 54,
                                  child: FilledButton(
                                    onPressed:
                                        (s == null || s.loading || s.submitting)
                                        ? null
                                        : () async {
                                            final d = ref
                                                .read(
                                                  futureLetterDraftStoreProvider,
                                                )
                                                .current;
                                            final noteId = d?.noteId;

                                            try {
                                              await controller.confirmAndSend();
                                              if (!context.mounted) return;
                                              Navigator.pushNamedAndRemoveUntil(
                                                context,
                                                FutureLetterRoutePaths.done,
                                                (r) => r.isFirst,
                                                arguments: {
                                                  'noteId': noteId,
                                                  'success': true,
                                                },
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              Navigator.pushNamed(
                                                context,
                                                FutureLetterRoutePaths.done,
                                                arguments: {
                                                  'noteId': noteId,
                                                  'success': false,
                                                  'message': e.toString(),
                                                },
                                              );
                                            }
                                          },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: theme.future.accent,
                                      foregroundColor: theme.future.onPrimary,
                                      disabledBackgroundColor: Colors.white
                                          .withValues(alpha: 0.08),
                                      disabledForegroundColor: theme
                                          .future
                                          .onPrimary
                                          .withValues(alpha: 0.35),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: (s != null && s.submitting)
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Confirm & Send',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final AppTheme theme;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final p = theme.future;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.accent.withValues(alpha: 0.2),
          ),
          child: Icon(
            icon,
            size: 22,
            color: p.onPrimary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: p.onPrimary.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.trim().isEmpty ? '-' : value,
                style: TextStyle(
                  color: p.onPrimary.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final dynamic theme;
  const _Chip({required this.icon, required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    final p = theme.future;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: p.onPrimary.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: p.onPrimary.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: p.onPrimary.withValues(alpha: 0.85),
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
