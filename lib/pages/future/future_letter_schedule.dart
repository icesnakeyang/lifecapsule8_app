import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/future/future_letter_provider.dart';
import 'package:lifecapsule8_app/utils/dt_localized.dart';

class FutureLetterSchedulePage extends ConsumerStatefulWidget {
  const FutureLetterSchedulePage({super.key});

  @override
  ConsumerState<FutureLetterSchedulePage> createState() =>
      _FutureLetterSchedulePageState();
}

class _FutureLetterSchedulePageState
    extends ConsumerState<FutureLetterSchedulePage> {
  DateTime? _pickedLocal;
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    final d = ref.read(futureLetterProvider).currentFutureLetter;
    if (d == null) {
      Future.microtask(() {
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    final iso = (d.sendAtIso ?? '').trim();
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed != null) _pickedLocal = parsed;
  }

  bool get _canNext => _pickedLocal != null;

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      initialDate: (_pickedLocal ?? now),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickedLocal ?? now),
    );
    if (time == null) return;

    setState(() {
      _pickedLocal = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _persistBeforeLeave() async {
    final notifier = ref.read(futureLetterProvider.notifier);

    // ✅ 把 UI 选中的时间写回 current（只更新内存/状态）
    if (_pickedLocal != null) {
      await notifier.setSendAtInMemory(sendAtLocal: _pickedLocal!);
    }

    // ✅ Next / Exit 规则：退出或下一步时，内容非空就落盘+上云
    await notifier.persistCurrentIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(futureLetterProvider).currentFutureLetter;

    final pickedText = _pickedLocal == null
        ? 'Not set'
        : formatLocalDateTime(context, _pickedLocal!);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _persistBeforeLeave();
        if (!context.mounted) return;
        Navigator.of(context).pop(result);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Schedule',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          // ✅ 关键：leading 返回也要触发 persist
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _persistBeforeLeave();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        ),
        body: d == null
            ? const Center(child: Text('No letter selected'))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Send at'),
                      subtitle: Text(pickedText),
                      trailing: TextButton(
                        onPressed: () => _pickDateTime(context),
                        child: const Text('Pick'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This letter will be delivered at the time you set.',
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await _persistBeforeLeave();
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            },
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _canNext
                                ? () async {
                                    await _persistBeforeLeave();
                                    if (!context.mounted) return;

                                    Navigator.pushNamed(
                                      context,
                                      '/FutureLetterRecipientPage',
                                    );
                                  }
                                : null,
                            child: const Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
