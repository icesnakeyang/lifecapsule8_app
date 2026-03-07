import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';

import 'package:lifecapsule8_app/features/love_letter/application/love_letter_send_time_controller.dart';
import 'package:lifecapsule8_app/features/love_letter/love_route_paths.dart';

class LoveLetterSendTimePage extends ConsumerStatefulWidget {
  final String? noteId;
  const LoveLetterSendTimePage({super.key, this.noteId});

  @override
  ConsumerState<LoveLetterSendTimePage> createState() =>
      _LoveLetterSendTimePageState();
}

class _LoveLetterSendTimePageState
    extends ConsumerState<LoveLetterSendTimePage> {
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final noteId = widget.noteId;
      if (noteId == null || noteId.trim().isEmpty) return;

      await ref
          .read(loveLetterSendTimeControllerProvider.notifier)
          .open(noteId: noteId);

      if (!mounted) return;
      setState(() => _hydrated = true);
    });
  }

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }

  Future<void> _pickDateTime() async {
    final s = ref.read(loveLetterSendTimeControllerProvider).value;
    final cur = s?.sendAtLocal;
    final now = DateTime.now();
    final initial = cur ?? now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    await ref
        .read(loveLetterSendTimeControllerProvider.notifier)
        .setSpecificTime(picked);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(loveLetterSendTimeControllerProvider);
    final s = async.value;

    final opening = s?.opening == true;
    final saving = s?.saving == true;

    final noteId = widget.noteId;
    final theme = ref.read(appThemeProvider);
    final palette = theme.loveLetter;

    return PopScope(
      canPop: !saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await ref.read(loveLetterSendTimeControllerProvider.notifier).save();
        if (!context.mounted) return;
        Navigator.of(context).pop(result);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true, // ✅
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'When to Send',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: palette.onPrimary,
            ),
          ),
          iconTheme: IconThemeData(color: palette.onPrimary),
          centerTitle: false,
          actions: [
            TextButton(
              onPressed: (saving || noteId == null || s?.canNext != true)
                  ? null
                  : () async {
                      await ref
                          .read(loveLetterSendTimeControllerProvider.notifier)
                          .save();
                      if (!context.mounted) return;

                      if (ref
                              .read(loveLetterSendTimeControllerProvider)
                              .value
                              ?.mode ==
                          LoveSendMode.later) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          LoveRoutePaths.list,
                          (route) => route.isFirst,
                        );

                        return;
                      }

                      Navigator.pushNamed(
                        context,
                        LoveRoutePaths.passcode,
                        arguments: {'noteId': noteId},
                      );
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: (s?.canNext == true)
                            ? palette.onPrimary
                            : palette.onPrimary.withOpacity(0.45),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: opening
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((s?.error ?? '').isNotEmpty) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.error,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      s!.error!,
                                      style: TextStyle(color: theme.onError),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Text(
                                  'When should this letter reach them?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: palette.onPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Choose the perfect moment for your words to arrive.',
                                  style: TextStyle(
                                    color: palette.onPrimary.withValues(
                                      alpha: 1,
                                    ),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _OptionCard(
                                  title: 'Specific Date & Time',
                                  subtitle: (s?.sendAtLocal == null)
                                      ? 'Tap to choose exact moment'
                                      : _fmt(s!.sendAtLocal!),
                                  icon: Icons.calendar_month_rounded,
                                  selected:
                                      s?.mode == LoveSendMode.specificTime,
                                  onTap: () async {
                                    final ctrl = ref.read(
                                      loveLetterSendTimeControllerProvider
                                          .notifier,
                                    );
                                    ctrl.setMode(LoveSendMode.specificTime);

                                    await _pickDateTime();
                                    await ctrl.flush();
                                  },
                                ),
                                const SizedBox(height: 12),
                                _OptionCard(
                                  title: 'Send Instantly',
                                  subtitle:
                                      'Deliver immediately after confirmation',
                                  icon: Icons.flash_on_rounded,
                                  selected: s?.mode == LoveSendMode.instantly,
                                  onTap: () {
                                    if (!_hydrated) return;
                                    ref
                                        .read(
                                          loveLetterSendTimeControllerProvider
                                              .notifier,
                                        )
                                        .setMode(LoveSendMode.instantly);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _OptionCard(
                                  title: 'Decide Later',
                                  subtitle: 'Keep it safe until you’re ready',
                                  icon: Icons.hourglass_empty_rounded,
                                  selected: s?.mode == LoveSendMode.later,
                                  onTap: () {
                                    if (!_hydrated) return;
                                    ref
                                        .read(
                                          loveLetterSendTimeControllerProvider
                                              .notifier,
                                        )
                                        .setMode(LoveSendMode.later);
                                  },
                                ),

                                const Spacer(),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends ConsumerWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(appThemeProvider);
    final palette = theme.loveLetter;

    final border = selected
        ? palette.onPrimary.withOpacity(0.55)
        : palette.onPrimary.withOpacity(0.18);
    final bg = selected
        ? palette.onPrimary.withOpacity(0.12)
        : Colors.white.withOpacity(0.04);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 26,
              color: selected
                  ? palette.onPrimary.withOpacity(0.95)
                  : palette.onPrimary.withOpacity(0.65),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: palette.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: palette.onPrimary.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.chevron_right_rounded,
              color: selected
                  ? palette.onPrimary.withOpacity(0.95)
                  : palette.onPrimary.withOpacity(0.55),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
