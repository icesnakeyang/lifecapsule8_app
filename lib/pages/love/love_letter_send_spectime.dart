// love_letter_send_spectime.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/love_letter/love_letter_provider.dart';

class LoveLetterSendSpectime extends ConsumerStatefulWidget {
  const LoveLetterSendSpectime({super.key});

  @override
  ConsumerState<LoveLetterSendSpectime> createState() =>
      _LoveLetterSendSpectimeState();
}

enum _SendMode { specificTime, primaryCountdown, instantly, later }

class _LoveLetterSendSpectimeState
    extends ConsumerState<LoveLetterSendSpectime> {
  bool _didInit = false;
  String? _noteId;

  _SendMode _mode = _SendMode.later;
  DateTime? _sendAt;

  String _fmt(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickSendTime() async {
    final now = DateTime.now();
    final initialDate = _sendAt ?? now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_sendAt ?? now),
    );
    if (time == null) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      _sendAt = picked;
      _mode = _SendMode.specificTime;
    });

    final noteId = _noteId;
    if (noteId != null) {
      // ✅ 选完立刻落盘（Hive）
      await ref
          .read(loveLetterProvider.notifier)
          .saveSendAt(noteId: noteId, sendAtLocal: picked);

      // ✅ 同步保存模式（按你现有 provider 自行实现）
      await ref
          .read(loveLetterProvider.notifier)
          .saveSendMode(noteId: noteId, mode: 'SPECIFIC_TIME');
    }
  }

  Future<void> _setMode(_SendMode mode) async {
    final noteId = _noteId;
    if (noteId == null) return;

    setState(() {
      _mode = mode;
    });

    final notifier = ref.read(loveLetterProvider.notifier);

    switch (mode) {
      case _SendMode.specificTime:
        // 不在这里落盘，等用户点选择时间
        await notifier.saveSendMode(noteId: noteId, mode: 'SPECIFIC_TIME');
        break;
      case _SendMode.primaryCountdown:
        await notifier.saveSendMode(noteId: noteId, mode: 'PRIMARY_COUNTDOWN');
        break;
      case _SendMode.instantly:
        await notifier.saveSendMode(noteId: noteId, mode: 'INSTANTLY');
        break;
      case _SendMode.later:
        await notifier.saveSendMode(noteId: noteId, mode: 'LATER');
    }
  }

  Future<void> _forceSaveNow() async {
    final noteId = _noteId;
    if (noteId == null) return;

    final notifier = ref.read(loveLetterProvider.notifier);

    // ✅ Preview 前：保证模式已写入（避免用户点了但没落盘）
    switch (_mode) {
      case _SendMode.specificTime:
        final sendAt = _sendAt;
        if (sendAt == null) return;
        await notifier.saveSendMode(noteId: noteId, mode: 'SPECIFIC_TIME');
        await notifier.saveSendAt(noteId: noteId, sendAtLocal: sendAt);
        break;
      case _SendMode.primaryCountdown:
        await notifier.saveSendMode(noteId: noteId, mode: 'PRIMARY_COUNTDOWN');
        break;
      case _SendMode.instantly:
        await notifier.saveSendMode(noteId: noteId, mode: 'INSTANTLY');
        break;
      case _SendMode.later:
        await notifier.saveSendMode(noteId: noteId, mode: 'LATER');
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _noteId = args?['noteId'] as String?;
    final noteId = _noteId;
    if (noteId == null) return;

    // ✅ 从 Hive 回填
    final d = ref.read(loveLetterProvider.notifier).getDraft(noteId);

    // 回填 sendAt
    final iso = d?.sendAtIso;
    final parsed = iso == null ? null : DateTime.tryParse(iso);
    if (parsed != null) _sendAt = parsed;

    // 回填 mode（按你 draft 字段名调整）
    final mode =
        d?.sendMode; // 例如：'SPECIFIC_TIME' | 'PRIMARY_COUNTDOWN' | 'INSTANTLY'
    if (mode == 'PRIMARY_COUNTDOWN') {
      _mode = _SendMode.primaryCountdown;
    } else if (mode == 'INSTANTLY') {
      _mode = _SendMode.instantly;
    } else if (mode == 'LATER') {
      _mode = _SendMode.later;
    } else {
      _mode = _SendMode.specificTime;
      // 如果有 sendAt 则显示，否则等待用户选
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteId = _noteId;

    final canNext =
        noteId != null && (_mode != _SendMode.specificTime || _sendAt != null);

    return Scaffold(
      appBar: AppBar(title: const Text('Send Time')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'When should this letter be delivered?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  // ✅ 选项 1：特定时间（保留你原来的 picker 卡片）
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await _setMode(_SendMode.specificTime);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _mode == _SendMode.specificTime
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.schedule,
                              color: _mode == _SendMode.specificTime
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Text(
                                      'Specific time',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () async {
                                        await _setMode(_SendMode.specificTime);
                                        await _pickSendTime();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: Icon(
                                          Icons.calendar_month_rounded,
                                          size: 18,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    ),

                                    Text(
                                      _sendAt == null
                                          ? 'Tap to set'
                                          : _fmt(_sendAt!),
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: _sendAt == null
                                            ? Colors.grey
                                            : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),
                                const Text(
                                  'The letter will be delivered at an exact date and time you choose.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 28,
                            child: Align(
                              alignment: AlignmentGeometry.centerRight,
                              child: _mode == _SendMode.specificTime
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    )
                                  : const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ 选项 2：Primary Countdown
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _setMode(_SendMode.primaryCountdown),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _mode == _SendMode.primaryCountdown
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: _mode == _SendMode.primaryCountdown
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Send by Primary Countdown',
                                  style: TextStyle(fontSize: 15),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'The letter will be sent automatically when your primary countdown reaches its end.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_mode == _SendMode.primaryCountdown)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          else
                            const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ 选项 3：Instantly
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _setMode(_SendMode.instantly),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _mode == _SendMode.instantly
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flash_on,
                            color: _mode == _SendMode.instantly
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Send now',
                                  style: TextStyle(fontSize: 15),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'The letter will be delivered as soon as you confirm.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_mode == _SendMode.instantly)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          else
                            const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ✅ 选项 4：Later
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _setMode(_SendMode.later),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _mode == _SendMode.later
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.pause,
                            color: _mode == _SendMode.later
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'I will decide later',
                                  style: TextStyle(fontSize: 15),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Your letter and settings will stay safe until you're ready",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_mode == _SendMode.later)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          else
                            const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canNext
                          ? () async {
                              if (_mode == _SendMode.later) {
                                await _forceSaveNow();
                                if (!context.mounted) return;

                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                                return;
                              }
                              await _forceSaveNow();
                              if (!context.mounted) return;
                              Navigator.pushNamed(
                                context,
                                '/LoveLetterPasscode',
                                arguments: {'noteId': noteId},
                              );
                            }
                          : null,
                      child: const Text('Next'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'You can always change this later',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
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
