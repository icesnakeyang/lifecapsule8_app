import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/i18n/locale_provider.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/core/utils/date_time_utils.dart';
import 'package:lifecapsule8_app/features/future_letter/application/future_letter_draft_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/future_letter_route_paths.dart';

class FutureLetterSchedulePage extends ConsumerWidget {
  final String noteId;

  const FutureLetterSchedulePage({super.key, required this.noteId});

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    WidgetRef ref,
    DateTime? init,
  ) async {
    final theme = ref.read(appThemeProvider);
    final now = DateTime.now();
    final initial = init ?? now;

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      initialDate: initial.isBefore(now) ? now : initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.future.accent,
              brightness: Brightness.dark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: theme.future.accent),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.future.accent,
              brightness: Brightness.dark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  DateTime? _parsePickedLocal(String? sendAtIso) {
    final iso = (sendAtIso ?? '').trim();
    if (iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    return dt.toLocal();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final locale = ref.watch(localeProvider).toString();

    final state = ref.watch(futureLetterDraftControllerProvider(noteId));
    final controller = ref.read(
      futureLetterDraftControllerProvider(noteId).notifier,
    );

    final palette = theme.future;
    final picked = _parsePickedLocal(state.draft.sendAtIso);

    final pickedText = picked == null
        ? 'Not set'
        : DateFormatter.dateTime(picked, locale: locale);

    final canNext = picked != null && !state.loading && !state.saving;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await controller.persist();
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
            'Schedule',
            style: TextStyle(
              color: theme.future.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.future.onPrimary),
            onPressed: () async {
              await controller.persist();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          centerTitle: false,
          actions: [
            TextButton(
              onPressed: canNext
                  ? () async {
                      await controller.persist();
                      if (!context.mounted) return;
                      Navigator.pushNamed(
                        context,
                        FutureLetterRoutePaths.recipient,
                        arguments: {'noteId': noteId},
                      );
                    }
                  : null,
              child: state.saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.future.onPrimary,
                      ),
                    )
                  : Text(
                      'Next',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.future.onPrimary,
                        fontSize: 16,
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
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Pick a delivery time',
                          style: TextStyle(
                            color: palette.onPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "We'll keep it safe and deliver it at your chosen moment.",
                          style: TextStyle(
                            color: palette.onPrimary.withValues(alpha: 0.72),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (state.error != null &&
                            state.error!.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: theme.error.withValues(alpha: 0.85),
                            ),
                            child: Text(
                              state.error!,
                              style: TextStyle(color: theme.onError),
                            ),
                          ),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: palette.accent.withValues(alpha: .5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            title: Text(
                              'Send at',
                              style: TextStyle(
                                color: theme.future.onPrimary.withValues(
                                  alpha: 0.75,
                                ),
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              pickedText,
                              style: TextStyle(
                                color: theme.future.onPrimary.withValues(
                                  alpha: 0.85,
                                ),
                                fontSize: 16,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                final dt = await _pickDateTime(
                                  context,
                                  ref,
                                  picked,
                                );
                                if (dt == null) return;
                                controller.setSchedule(
                                  dt.toUtc().toIso8601String(),
                                );
                              },
                              child: Icon(
                                Icons.calendar_today_rounded,
                                size: 24,
                                color: theme.future.onPrimary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'This letter will be delivered at the time you set.',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: theme.future.onPrimary.withValues(
                              alpha: 0.75,
                            ),
                            fontSize: 16,
                          ),
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
