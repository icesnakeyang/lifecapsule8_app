import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/appication/future_letter_draft_store.dart';
import 'package:lifecapsule8_app/features/future_letter/appication/future_letter_list_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/appication/future_letter_write_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/future_letter_route_paths.dart';

class FutureLetterWritePage extends ConsumerStatefulWidget {
  final String? noteId;

  const FutureLetterWritePage({super.key, this.noteId});

  @override
  ConsumerState<FutureLetterWritePage> createState() =>
      _FutureLetterWritePageState();
}

class _FutureLetterWritePageState extends ConsumerState<FutureLetterWritePage> {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  bool _hydrated = false;

  @override
  void initState() {
    super.initState();

    // ✅ 输入只更新内存（DraftStore current）
    _textCtrl.addListener(() {
      if (!_hydrated) return;
      ref
          .read(futureLetterWriteControllerProvider.notifier)
          .setContentInMemory(_textCtrl.text);
      setState(() {}); // 只用于 Next enable
    });

    // ✅ 首帧后 hydrate（避免 build 期间 setText）
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cur = await ref
          .read(futureLetterWriteControllerProvider.notifier)
          .open(noteId: widget.noteId);
      if (!mounted) return;

      _textCtrl.text = cur.content;
      _hydrated = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _persistOnExitOrNext() async {
    // 兜底：把 controller 最新值写回内存（避免漏最后一次输入）
    ref
        .read(futureLetterWriteControllerProvider.notifier)
        .setContentInMemory(_textCtrl.text);

    // ✅ 统一交给 controller -> DraftStore.persistNowIfNeeded()
    await ref
        .read(futureLetterWriteControllerProvider.notifier)
        .persistBeforeLeave();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 触发 write controller build（确保 ensureCurrentInMemory 在 provider 生命周期里跑）
    ref.watch(futureLetterWriteControllerProvider);

    final theme = ref.watch(appThemeProvider);
    final palette = theme.future;

    // ✅ DraftStore 是 State（不是 AsyncValue）
    final store = ref.watch(futureLetterDraftStoreProvider);
    final cur = store.current;

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
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'To Future',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.future.onPrimary,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.future.onPrimary),
            onPressed: () async {
              await _persistOnExitOrNext();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Unfocus',
              onPressed: () => _focusNode.unfocus(),
              icon: Icon(
                Icons.keyboard_hide,
                color: theme.future.accent,
                size: 24,
              ),
            ),
            IconButton(
              tooltip: 'All letters',
              icon: Icon(Icons.list, size: 24, color: theme.future.onPrimary),
              onPressed: () async {
                await _persistOnExitOrNext();
                await ref.read(futureLetterListControllerProvider.notifier).refresh();
                if (!context.mounted) return;
                Navigator.pushNamed(context, FutureLetterRoutePaths.list);
              },
            ),
            TextButton(
              onPressed: canNext
                  ? () async {
                      await _persistOnExitOrNext();
                      if (!context.mounted) return;
                      Navigator.pushNamed(
                        context,
                        FutureLetterRoutePaths.schedule,
                        arguments: {'noteId': cur!.noteId},
                      );
                    }
                  : null,
              child: Text(
                'Next',
                style: TextStyle(
                  color: canNext
                      ? theme.future.onPrimary
                      : theme.future.onPrimary.withValues(alpha: 0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: cur == null
            ? const Center(child: CircularProgressIndicator())
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.future.gradientStart,
                      theme.future.gradientEnd,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textCtrl,
                          maxLines: null,
                          expands: true,
                          focusNode: _focusNode,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.55,
                            color: theme.future.onPrimary,
                          ),
                          cursorColor: theme.future.accent.withValues(
                            alpha: 0.8,
                          ),
                          decoration: InputDecoration(
                            fillColor: Colors.transparent,
                            hintText: 'Write your letter…',
                            hintStyle: TextStyle(
                              color: theme.future.onPrimary.withValues(
                                alpha: 0.45,
                              ),
                              fontStyle: FontStyle.italic,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
