import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/future/future_letter_provider.dart';
import 'package:lifecapsule8_app/utils/dt_localized.dart';

class FutureLetterPreviewPage extends ConsumerStatefulWidget {
  const FutureLetterPreviewPage({super.key});

  @override
  ConsumerState<FutureLetterPreviewPage> createState() =>
      _FutureLetterPreviewPageState();
}

class _FutureLetterPreviewPageState
    extends ConsumerState<FutureLetterPreviewPage> {
  bool _inited = false;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    final cur = ref.read(futureLetterProvider).currentFutureLetter;
    if (cur == null) {
      Future.microtask(() {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _persistBeforeLeave() async {
    // ✅ 退出/Back/Confirm 前：统一保存（内容非空才落盘+上云，且 sig 去重）
    await ref.read(futureLetterProvider.notifier).persistCurrentIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(futureLetterProvider).currentFutureLetter;
    final errMsg = ref.watch(futureLetterProvider).errMsg;

    final scheduleText = () {
      final iso = (draft?.sendAtIso ?? '').trim();
      if (iso.isEmpty) return '-';
      final dt = DateTime.tryParse(iso)?.toLocal();
      if (dt == null) return iso;
      return formatLocalDateTime(context, dt);
    }();

    final userCode = (draft?.userCode ?? '').trim();
    final email = (draft?.email ?? '').trim();

    String recipientText;
    if (draft == null) {
      recipientText = '-';
    } else if (userCode.isNotEmpty && email.isNotEmpty) {
      recipientText = 'UserCode: $userCode\nEmail: $email';
    } else if (userCode.isNotEmpty) {
      recipientText = 'UserCode: $userCode';
    } else if (email.isNotEmpty) {
      recipientText = 'Email: $email';
    } else {
      recipientText = '-';
    }

    final toName = (draft?.toName ?? '').trim();
    final fromName = (draft?.fromName ?? '').trim();
    final content = (draft?.content ?? '').trim();

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
            'Preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _submitting
                ? null
                : () async {
                    await _persistBeforeLeave();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
          ),
        ),
        body: draft == null
            ? const Center(child: Text('No letter selected'))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errMsg != null && errMsg.trim().isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.errorContainer,
                        ),
                        child: Text(
                          errMsg,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Text(
                      'Schedule',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(scheduleText),
                    const SizedBox(height: 12),

                    const Text(
                      'Recipient',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(recipientText),
                    const SizedBox(height: 12),

                    const Text(
                      'Names',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('To: ${toName.isEmpty ? '-' : toName}'),
                    Text('From: ${fromName.isEmpty ? '-' : fromName}'),
                    const SizedBox(height: 12),

                    const Text(
                      'Content',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.55),
                        ),
                        child: content.isEmpty
                            ? Text(
                                '-',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              )
                            : SingleChildScrollView(
                                child: SelectableText(
                                  content,
                                  style: const TextStyle(height: 1.4),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting
                                  ? null
                                  : () async {
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
                              onPressed: _submitting
                                  ? null
                                  : () async {
                                      setState(() => _submitting = true);
                                      try {
                                        // ✅ Confirm 前，确保已落盘+上云 note_base/content
                                        await _persistBeforeLeave();

                                        // ✅ 这里才是“创建 send_task 并同步云端”
                                        await ref
                                            .read(futureLetterProvider.notifier)
                                            .confirmSendCurrent();

                                        if (!context.mounted) return;
                                        Navigator.popUntil(
                                          context,
                                          (r) => r.isFirst,
                                        );
                                      } catch (_) {
                                        if (mounted) {
                                          setState(() => _submitting = false);
                                        }
                                      }
                                    },
                              child: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Confirm',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
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
