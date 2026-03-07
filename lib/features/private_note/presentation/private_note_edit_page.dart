import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/constants/onboarding_keys.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/private_note/appication/private_note_edit_controller.dart';
import 'package:lifecapsule8_app/features/private_note/private_note_route_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivateNoteEditPage extends ConsumerStatefulWidget {
  final String? noteId;
  const PrivateNoteEditPage({super.key, this.noteId});

  @override
  ConsumerState<PrivateNoteEditPage> createState() =>
      _PrivateNoteEditPageState();
}

class _PrivateNoteEditPageState extends ConsumerState<PrivateNoteEditPage>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _hydrated = false;
  bool _savingOnce = false;
  bool _opened = false;

  // tip dialog control
  bool _isDialogClosed = false;
  bool _shouldAutoFocusAfterHydrate = false;

  Future<void> _saveOnce() async {
    if (_savingOnce) return;
    _savingOnce = true;
    try {
      await ref.read(privateNoteEditControllerProvider.notifier).save();
    } finally {
      _savingOnce = false;
    }
  }

  void _toggleKeyboard() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 初始禁止抢焦点，避免一进来就弹键盘
    _focusNode.canRequestFocus = false;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // 先处理提示弹窗 + 焦点策略
      await _maybeShowTipAndPrepareFocus();

      // 再打开 note
      if (!mounted || _opened) return;
      _opened = true;

      await ref
          .read(privateNoteEditControllerProvider.notifier)
          .open(noteId: widget.noteId);

      if (!mounted) return;

      final s = ref.read(privateNoteEditControllerProvider).value;
      _controller.text = s?.note?.content ?? '';
      if (!mounted) return;

      setState(() => _hydrated = true);

      // 如果不需要弹窗（或已关闭），在 hydrate 之后再请求焦点更稳
      if (_focusNode.canRequestFocus &&
          (_isDialogClosed || _shouldAutoFocusAfterHydrate)) {
        _requestInputFocus();
      }
    });
  }

  Future<void> _maybeShowTipAndPrepareFocus() async {
    final prefs = await SharedPreferences.getInstance();
    final section = OnboardingKeys.privateNote;

    final countKey = OnboardingKeys.entryCountKey(section);
    final tipKey = OnboardingKeys.tipShownKey(section);

    final oldCount = prefs.getInt(countKey) ?? 0;
    final entryCount = oldCount + 1;
    await prefs.setInt(countKey, entryCount);

    // 规则：前 30 次进入、且未展示过，显示提示
    if (entryCount <= 300) {
      _focusNode.canRequestFocus = false;
      _isDialogClosed = false;
      await _showCombinedTipDialog(prefs, tipKey);
      return;
    }

    // 不弹窗：允许后续自动聚焦（等 hydrate 后再聚焦）
    _shouldAutoFocusAfterHydrate = true;
    _focusNode.canRequestFocus = true;
  }

  Future<void> _showCombinedTipDialog(
    SharedPreferences prefs,
    String tipKey,
  ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final theme = ref.read(appThemeProvider);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.book, size: 20, color: theme.primary),
                      const SizedBox(width: 12),

                      Text(
                        'Private Note',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    // 'This is your private space.\n\n'
                    // 'Start with something simple:\n\n'
                    // '• What are you feeling right now?\n'
                    // '• What happened today that stayed with you?\n'
                    // '• What are you not saying out loud?\n\n'
                    // 'No pressure.\n'
                    // 'No judgment.\n\n'
                    // 'Just you and your thoughts.',
                    'This is your private space.\n\n'
                    'One day, you will look back at this page.\n'
                    'And remember who you were today.\n\n'
                    'Write what this moment feels like.\n'
                    'Even the small things matter.\n\n'
                    'Just you and your thoughts.',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.onSurface.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx,rootNavigator: true).pop(),
                      child: Text(
                        'Got it',
                        style: TextStyle(
                          color: theme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) async {
      // 点击空白处关闭 or 点击 Got it 都会走到这里
      if (!mounted) return;
      if (_isDialogClosed) return;

      _isDialogClosed = true;

      prefs.setBool(tipKey, true);
      _focusNode.canRequestFocus = true;

      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _requestInputFocus();
      });
    });
  }

  void _requestInputFocus() {
    if (!mounted || !_focusNode.canRequestFocus) return;
    _focusNode.requestFocus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveOnce(); // 不 await：避免阻塞生命周期回调
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(appThemeProvider);
    final async = ref.watch(privateNoteEditControllerProvider);
    final s = async.value;

    final saving = s?.saving == true;
    final opening = s?.opening == true;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        await _saveOnce();
        if (!nav.mounted) return;
        nav.pop(result);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Private Note',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _toggleKeyboard();
                });
              },
              icon: Icon(
                _focusNode.hasFocus ? Icons.keyboard_hide : Icons.keyboard,
              ),
            ),
            IconButton(
              onPressed: () async {
                await _saveOnce();
                if (!context.mounted) return;
                Navigator.of(context).pushNamed(PrivateNoteRoutePaths.list);
              },
              icon: Icon(Icons.list_alt, color: theme.privateNote.primary),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      await _saveOnce();
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.pushNamed(context, PrivateNoteRoutePaths.list);
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 17,
                        color: theme.privateNote.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
        body: opening
            ? const Center(child: CircularProgressIndicator())
            : Container(
                color: theme.surface,
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Write your mind here safely…',
                    hintStyle: TextStyle(
                      color: theme.onSurface.withValues(alpha: 0.35),
                      fontSize: 18,
                    ),
                    filled: false,

                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: theme.onSurface,
                  ),
                  cursorColor: theme.privateNote.primary.withValues(alpha: 0.7),
                  cursorWidth: 1.6,
                  cursorRadius: const Radius.circular(1),
                  onChanged: (v) {
                    if (!_hydrated) return;
                    ref
                        .read(privateNoteEditControllerProvider.notifier)
                        .setContent(v);
                  },
                ),
              ),
      ),
    );
  }
}
