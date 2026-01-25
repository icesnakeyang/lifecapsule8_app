// lib/pages/love_letter/love_letter.dart
// ✅ LoveLetter 编辑页：不再依赖 noteProvider，改用 loveLetterProvider（Hive drafts）
// ✅ 自动保存：输入变更 -> 写入 draftBox
// ✅ 退回/切后台也会保存
// ✅ 下次再进页面：继续显示上次内容

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/love_letter/love_letter_provider.dart';

class LoveLetter extends ConsumerStatefulWidget {
  const LoveLetter({super.key});

  @override
  ConsumerState<LoveLetter> createState() => _LoveLetterState();
}

class _LoveLetterState extends ConsumerState<LoveLetter>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _inited = false;
  String? _noteId;

  Timer? _debounce;
  late final VoidCallback _onTextChanged;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _onTextChanged = () {
      final id = _noteId;
      if (id == null) return;

      // 防抖：避免每个字符写 Hive
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () async {
        if (!mounted) return;
        await ref
            .read(loveLetterProvider.notifier)
            .saveContent(noteId: id, content: _controller.text);
      });
    };

    _controller.addListener(_onTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _initLoveLetter();
    });
  }

  Future<void> _initLoveLetter() async {
    final notifier = ref.read(loveLetterProvider.notifier);

    // 1) 创建/获取当前 noteId（放在 draft 里）
    final noteId = await notifier.ensureCurrentNoteId();
    _noteId = noteId;

    // 2) 确保 draft 存在
    final draft = await notifier.ensureDraft(noteId);

    if (!mounted) return;

    // 3) 回填内容
    _controller.text = draft.content ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_focusNode.canRequestFocus) _focusNode.requestFocus();
    });

    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _flushSave();
    }
  }

  Future<void> _flushSave() async {
    final id = _noteId;
    if (id == null) return;
    _debounce?.cancel();
    await ref
        .read(loveLetterProvider.notifier)
        .saveContent(noteId: id, content: _controller.text);
  }

  Future<void> _saveOrDeleteBeforeExit() async {
    final id = _noteId;
    if (id == null) return;
    await ref
        .read(loveLetterProvider.notifier)
        .saveOrDeleteDraft(noteId: id, content: _controller.text);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final canNext = text.trim().isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        await _saveOrDeleteBeforeExit();
        if (!nav.mounted) return;
        nav.pop(result);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Love Letter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
            ),
          ),
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () async {
                await _saveOrDeleteBeforeExit();
                if (!mounted) return;
                Navigator.pushNamed(context, '/LoveLetterList');
              },
            ),
            TextButton(
              onPressed: canNext
                  ? () async {
                      await _flushSave();
                      if (!mounted) return;
                      Navigator.pushNamed(context, '/LoveLetterNext2');
                    }
                  : null,
              child: Text(
                'Next',
                style: TextStyle(
                  color: canNext ? Colors.white : Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(158, 135, 2, 111),
                Color.fromARGB(255, 41, 1, 23),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      scrollPadding: EdgeInsets.zero,
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText:
                            'Dear...\n\n'
                            "I keep thinking about you.\n"
                            "The way you look at me stirs something deep indide, "
                            "and I can't seem to focus on anything else.\n\n"
                            "I don't know how to say this out loud.\n"
                            "I want to see you.\n"
                            "No matter what happens, I want to be with you.",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          height: 1.8,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
