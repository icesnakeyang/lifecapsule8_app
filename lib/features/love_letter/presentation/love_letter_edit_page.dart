import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/constants/onboarding_keys.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/love_letter/application/love_letter_edit_controller.dart';
import 'package:lifecapsule8_app/features/love_letter/application/love_letter_list_controller.dart';
import 'package:lifecapsule8_app/features/love_letter/love_route_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoveLetterEditPage extends ConsumerStatefulWidget {
  final String? noteId;
  const LoveLetterEditPage({super.key, this.noteId});

  @override
  ConsumerState<LoveLetterEditPage> createState() => _LoveLetterEditPageState();
}

class _LoveLetterEditPageState extends ConsumerState<LoveLetterEditPage>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _inited = false;
  Timer? _debounce;
  late final VoidCallback _onTextChanged;
  bool _tipShown = false;
  final bool _shouldRequestFocus = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _onTextChanged = () {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () async {
        if (!mounted) return;
        final notifier = ref.read(loveLetterEditControllerProvider.notifier);
        if (notifier.currentNoteId == null) return;
        notifier.setContent(_controller.text);
        await notifier.save();
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

      final ctl = ref.read(loveLetterEditControllerProvider.notifier);
      await ctl.open(noteId: widget.noteId);

      final asyncValue = ref.read(loveLetterEditControllerProvider);
      final content = asyncValue.value?.note?.content ?? '';
      _controller.text = content;

      await _checkAndShowTip();

      if (_shouldRequestFocus && mounted && _focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }

      if (mounted) setState(() {});
    });
  }

  Future<void> _checkAndShowTip() async {
    if (_tipShown) return;
    final prefs = await SharedPreferences.getInstance();
    final section = OnboardingKeys.loveLetter;
    final countKey = OnboardingKeys.entryCountKey(section);
    int count = prefs.getInt(countKey) ?? 0;
    count++;
    await prefs.setInt(countKey, count);

    final hasShown =
        prefs.getBool(OnboardingKeys.tipShownKey(section)) ?? false;
    if (count <= 300 && !hasShown) {
      _tipShown = true;
      await _showTipDialog(prefs, count);
    }
  }

  Future<void> _showTipDialog(SharedPreferences prefs, int currentCount) async {
    if (!mounted) return;

    const dialogBg = Color.fromARGB(220, 148, 4, 90);
    const accentColor = Color(0xFFF06292);
    final textColor = Colors.white.withOpacity(0.92);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.favorite_border_rounded,
                size: 22,
                color: accentColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Love Letters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          content: Text(
            'Your secret place to write love letters.\n\n'
            'Express what words fail to say — to a crush, lover, future self, or lost one.\n\n'
            'Set a condition… and let the universe decide if and when it reaches them.\n\n'
            'Write honestly. Everything stays private.',
            style: TextStyle(fontSize: 18, height: 1.4, color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (currentCount >= 3) {
                  prefs.setBool(
                    OnboardingKeys.tipShownKey(OnboardingKeys.loveLetter),
                    true,
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: accentColor),
              child: const Text('Got It'),
            ),
          ],
        );
      },
    );
  }

  void _toggleKeyboard() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _flushSave();
    }
  }

  Future<void> _flushSave() async {
    _debounce?.cancel();
    final notifier = ref.read(loveLetterEditControllerProvider.notifier);
    final noteId = notifier.currentNoteId;
    if (noteId == null) return;

    notifier.setContent(_controller.text);
    await notifier.save();
  }

  Future<void> _saveOrDeleteBeforeExit() async {
    final notifier = ref.read(loveLetterEditControllerProvider.notifier);
    final noteId = notifier.currentNoteId;
    if (noteId == null) return;

    await notifier.saveOrDeleteCurrent(_controller.text);
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
    final theme = ref.read(appThemeProvider);
    final palette = theme.loveLetter;
    final editAsync = ref.watch(loveLetterEditControllerProvider);
    final isSaving = editAsync.value?.isSaving ?? false;
    final text = _controller.text;
    final canNext = text.trim().isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _saveOrDeleteBeforeExit();
        if (!context.mounted) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Love Letter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: palette.onPrimary,
            ),
          ),
          iconTheme: IconThemeData(color: palette.onPrimary),
          actions: [
            if (isSaving)
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.onPrimary,
                  ),
                ),
              ),
            IconButton(
              icon: Icon(
                _focusNode.hasFocus ? Icons.keyboard_hide : Icons.keyboard,
                size: 26,
              ),
              onPressed: _toggleKeyboard,
            ),
            IconButton(
              icon: const Icon(Icons.list, size: 28),
              onPressed: () async {
                await _saveOrDeleteBeforeExit();
                if (!context.mounted) return;
                ref.invalidate(loveLetterListControllerProvider);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  LoveRoutePaths.list,
                  (route) => route.isFirst,
                );
              },
            ),
            TextButton(
              onPressed: canNext && !isSaving
                  ? () async {
                      await _flushSave();
                      if (!context.mounted) return;

                      final currentNoteId = ref
                          .read(loveLetterEditControllerProvider.notifier)
                          .currentNoteId;
                      if (currentNoteId == null) return;

                      Navigator.pushNamed(
                        context,
                        LoveRoutePaths.action,
                        arguments: {'noteId': currentNoteId},
                      );
                    }
                  : null,
              child: Text(
                'Next',
                style: TextStyle(
                  color: canNext && !isSaving
                      ? palette.onPrimary
                      : palette.onSurfaceDim,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  isCollapsed: true, // 🔥 关键：移除默认 padding
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,

                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,

                  hintText:
                      'Dear...\n\n'
                      "I keep thinking about you.\n"
                      "The way you look at me stirs something deep inside, "
                      "and I can't seem to focus on anything else.\n\n"
                      "I don't know how to say this out loud.\n"
                      "I want to see you.\n"
                      "No matter what happens, I want to be with you.",
                  hintStyle: TextStyle(
                    color: palette.onSurfaceDim,
                    fontSize: 17,
                    height: 1.7,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
