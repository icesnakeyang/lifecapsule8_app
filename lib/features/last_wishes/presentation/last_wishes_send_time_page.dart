import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/features/last_wishes/application/last_wishes_send_time_controller.dart';
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_route_paths.dart';

class LastWishesSendTimePage extends ConsumerStatefulWidget {
  final String? noteId;

  const LastWishesSendTimePage({super.key, this.noteId});

  @override
  ConsumerState<LastWishesSendTimePage> createState() =>
      _LastWishesSendTimePageState();
}

class _LastWishesSendTimePageState
    extends ConsumerState<LastWishesSendTimePage> {
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(lastWishesSendTimeControllerProvider.notifier);

      String? noteId = widget.noteId;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (noteId == null && args is Map) {
        noteId = args['noteId'] as String?;
      }

      await notifier.setNoteId(noteId);
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 50),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    await ref.read(lastWishesSendTimeControllerProvider.notifier).setSendAt(dt);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(lastWishesSendTimeControllerProvider);

    return asyncState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Send Time')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (s) {
        final notifier = ref.read(
          lastWishesSendTimeControllerProvider.notifier,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Send Time'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: notifier.canGoNext
                    ? () async {
                        await notifier.saveNow();
                        if (!context.mounted) return;
                        Navigator.pushNamed(
                          context,
                          LastWishesRoutePaths.recipient,
                          arguments: {'noteId': s.noteId},
                        );
                      }
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                if (s.error != null && s.error!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.25)),
                    ),
                    child: Text(
                      s.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                _ModeCard(
                  title: 'After a waiting period',
                  subtitle:
                      'We will wait 1 / 5 / 10 / 20 years, then start the confirmation process.',
                  selected: s.mode == LastWishesSendMode.afterYears,
                  onTap: () async {
                    await notifier.setMode(LastWishesSendMode.afterYears);
                  },
                ),
                const SizedBox(height: 10),

                if (s.mode == LastWishesSendMode.afterYears)
                  _YearsChips(
                    value: s.waitingYears,
                    onSelect: (y) async => notifier.setWaitingYears(y),
                  ),

                const SizedBox(height: 18),

                _ModeCard(
                  title: 'Send at a specific time',
                  subtitle: 'Choose an exact date & time in the future.',
                  selected: s.mode == LastWishesSendMode.specificTime,
                  onTap: () async {
                    await notifier.setMode(LastWishesSendMode.specificTime);
                    await _pickDateTime();
                  },
                ),
                const SizedBox(height: 10),

                if (s.mode == LastWishesSendMode.specificTime)
                  _SpecificTimeRow(
                    value: s.sendAt,
                    onPick: _pickDateTime,
                    onClear: () async {
                      await notifier.setMode(LastWishesSendMode.specificTime);
                    },
                  ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    if (s.saving) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      const Text('Saving...'),
                    ] else
                      const Text(''),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? Colors.black.withOpacity(0.05)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? Colors.black.withOpacity(0.22)
                  : Colors.black.withOpacity(0.08),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearsChips extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onSelect;

  const _YearsChips({required this.value, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const options = [1, 5, 10, 20];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final y in options)
          ChoiceChip(
            selected: value == y,
            label: Text('$y year${y == 1 ? '' : 's'}'),
            onSelected: (_) => onSelect(y),
          ),
      ],
    );
  }
}

class _SpecificTimeRow extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _SpecificTimeRow({
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Not set'
        : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')} '
              '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(onPressed: onPick, child: const Text('Pick')),
        ],
      ),
    );
  }
}
