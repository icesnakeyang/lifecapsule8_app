import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/future/future_letter_provider.dart';

class FutureLetterWritePage extends ConsumerStatefulWidget {
  const FutureLetterWritePage({super.key});

  @override
  ConsumerState<FutureLetterWritePage> createState() =>
      _FutureLetterWritePageState();
}

class _FutureLetterWritePageState extends ConsumerState<FutureLetterWritePage> {
  final _textCtrl = TextEditingController();
  bool _inited = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cur = ref.read(futureLetterProvider.notifier).ensureCurrentDraft();
      if (!mounted) return;

      _textCtrl.text = cur.content;
      _inited = true;
      setState(() {});
    });

    // ✅ 输入只更新内存，不落盘不上云
    _textCtrl.addListener(() {
      if (!_inited) return;
      ref
          .read(futureLetterProvider.notifier)
          .setCurrentContentInMemory(_textCtrl.text);
      setState(() {}); // 只用于 Next enable
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _persistOnExitOrNext() async {
    // 先把 controller 最新值写回 provider（防丢最后一次输入）
    ref
        .read(futureLetterProvider.notifier)
        .setCurrentContentInMemory(_textCtrl.text);

    // ✅ 只在 Next/Exit 持久化（hive + 云端）
    await ref.read(futureLetterProvider.notifier).persistCurrentIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final cur = ref.watch(futureLetterProvider).currentFutureLetter;
    final canNext = _textCtrl.text.trim().isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _persistOnExitOrNext();
        if (!context.mounted) return;
        Navigator.of(context).pop(result);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Write Letter To Future',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _persistOnExitOrNext();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              tooltip: 'All letters',
              icon: const Icon(Icons.list),
              onPressed: () async {
                await _persistOnExitOrNext();
                if (!context.mounted) return;
                Navigator.pushNamed(context, '/FutureLetterListPage');
              },
            ),
          ],
        ),
        body: cur == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(0),
                child: Column(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: 'Write your letter…',
                          alignLabelWithHint: true,
                          contentPadding: EdgeInsets.all(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: canNext
                              ? () async {
                                  await _persistOnExitOrNext();
                                  if (!context.mounted) return;
                                  Navigator.pushNamed(
                                    context,
                                    '/FutureLetterSchedulePage',
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
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
