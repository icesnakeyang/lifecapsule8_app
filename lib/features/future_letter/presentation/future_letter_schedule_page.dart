import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/i18n/locale_provider.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/core/utils/date_time_utils.dart';
import 'package:lifecapsule8_app/features/future_letter/appication/future_letter_schedule_controller.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final locale = ref.watch(localeProvider).toString();
    final asyncState = ref.watch(futureLetterScheduleControllerProvider);
    final controller = ref.read(
      futureLetterScheduleControllerProvider.notifier,
    );

    final s = asyncState.value;
    final picked = s?.pickedLocal;

    final pickedText = picked == null
        ? 'Not set'
        : DateFormatter.formatDateTime(picked, locale);

    final palette = theme.future;

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
              await controller.persistBeforeLeave();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          centerTitle: false,
          actions: [
            TextButton(
              onPressed: (s == null || !controller.canNext)
                  ? null
                  : () async {
                      await controller.persistBeforeLeave();
                      if (!context.mounted) return;
                      Navigator.pushNamed(
                        context,
                        FutureLetterRoutePaths.recipient,
                        arguments: {'noteId': noteId},
                      );
                    },
              child: Text(
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
            child: asyncState.isLoading
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

                        if (s?.error != null && (s!.error!).trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: theme.error.withValues(alpha: 0.85),
                            ),
                            child: Text(
                              s.error!,
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
                                color: theme.future.onPrimary.withOpacity(0.85),
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
                                controller.setPickedLocal(dt);
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

DateTime _addMonthsSafe(DateTime dt, int months) {
  final y = dt.year + ((dt.month - 1 + months) ~/ 12);
  final m = ((dt.month - 1 + months) % 12) + 1;
  final lastDay = DateTime(y, m + 1, 0).day;
  final d = dt.day > lastDay ? lastDay : dt.day;
  return DateTime(y, m, d, dt.hour, dt.minute);
}
