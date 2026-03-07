import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/app_theme.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';

import 'package:lifecapsule8_app/features/love_letter/application/love_letter_passcode_controller.dart';
import 'package:lifecapsule8_app/features/love_letter/love_route_paths.dart';

class LoveLetterPasscodePage extends ConsumerStatefulWidget {
  final String? noteId;
  const LoveLetterPasscodePage({super.key, this.noteId});

  @override
  ConsumerState<LoveLetterPasscodePage> createState() =>
      _LoveLetterPasscodePageState();
}

class _LoveLetterPasscodePageState
    extends ConsumerState<LoveLetterPasscodePage> {
  bool _hydrated = false;

  // PASSCODE
  final _passCtl = TextEditingController();
  final _pass2Ctl = TextEditingController();
  bool _showPass = false;

  // QA
  final _qCtl = TextEditingController();
  final _aCtl = TextEditingController();
  final _a2Ctl = TextEditingController();
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();

    _passCtl.addListener(_onAnyChanged);
    _pass2Ctl.addListener(_onAnyChanged);
    _qCtl.addListener(_onAnyChanged);
    _aCtl.addListener(_onAnyChanged);
    _a2Ctl.addListener(_onAnyChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final noteId = widget.noteId;
      if (noteId == null || noteId.trim().isEmpty) return;

      await ref
          .read(loveLetterPasscodeControllerProvider.notifier)
          .open(noteId: noteId);

      if (!mounted) return;

      final s = ref.read(loveLetterPasscodeControllerProvider).value;
      final mode = s?.mode ?? LovePassMode.none;

      // 回填
      if (mode == LovePassMode.passcode) {
        final p = s?.passcode ?? '';
        _passCtl.text = p;
        _pass2Ctl.text = p.isEmpty ? '' : p;
      } else if (mode == LovePassMode.qa) {
        final payload = s?.qaPayload;
        if (payload != null && payload.trim().isNotEmpty) {
          try {
            final map = jsonDecode(payload) as Map<String, dynamic>;
            _qCtl.text = (map['q'] as String?) ?? '';
            final a = (map['a'] as String?) ?? '';
            _aCtl.text = a;
            _a2Ctl.text = a.isEmpty ? '' : a;
          } catch (_) {}
        }
      }

      setState(() => _hydrated = true);
    });
  }

  void _onAnyChanged() {
    if (!_hydrated) return;
    setState(() {});
    ref
        .read(loveLetterPasscodeControllerProvider.notifier)
        .onUiChanged(
          pass1: _passCtl.text,
          pass2: _pass2Ctl.text,
          q: _qCtl.text,
          a1: _aCtl.text,
          a2: _a2Ctl.text,
        );
  }

  bool get _isPassOk {
    final p1 = _passCtl.text.trim();
    final p2 = _pass2Ctl.text.trim();
    if (p1.isEmpty || p2.isEmpty) return false;
    return p1 == p2;
  }

  bool get _isQaOk {
    final q = _qCtl.text.trim();
    final a1 = _aCtl.text.trim();
    final a2 = _a2Ctl.text.trim();
    if (q.isEmpty || a1.isEmpty || a2.isEmpty) return false;
    return a1 == a2;
  }

  bool _canNext(LovePassMode mode) {
    switch (mode) {
      case LovePassMode.none:
        return true;
      case LovePassMode.passcode:
        return _isPassOk;
      case LovePassMode.qa:
        return _isQaOk;
    }
  }

  @override
  void dispose() {
    _passCtl.removeListener(_onAnyChanged);
    _pass2Ctl.removeListener(_onAnyChanged);
    _qCtl.removeListener(_onAnyChanged);
    _aCtl.removeListener(_onAnyChanged);
    _a2Ctl.removeListener(_onAnyChanged);

    _passCtl.dispose();
    _pass2Ctl.dispose();
    _qCtl.dispose();
    _aCtl.dispose();
    _a2Ctl.dispose();
    super.dispose();
  }

  // ===== theme helpers (ONLY appThemeProvider) =====

  Color _fieldFill(AppTheme theme) => Colors.white.withOpacity(0.10);
  Color _border(AppTheme theme) => theme.loveLetter.onPrimary.withOpacity(0.22);
  Color _borderFocus(AppTheme theme) =>
      theme.loveLetter.onPrimary.withOpacity(0.55);

  InputDecoration _decor(
    AppTheme theme, {
    required String label,
    String? hint,
    String? helper,
    Widget? suffix,
  }) {
    final on = theme.loveLetter.onPrimary;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperStyle: TextStyle(color: on.withOpacity(0.60)),
      labelStyle: TextStyle(color: on.withOpacity(0.85)),
      hintStyle: TextStyle(color: on.withOpacity(0.55)),
      filled: true,
      fillColor: _fieldFill(theme),
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _border(theme)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderFocus(theme), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.error, width: 1.6),
      ),
      suffixIcon: suffix,
    );
  }

  TextStyle _inputStyle(AppTheme theme) => TextStyle(
    color: theme.loveLetter.onPrimary.withOpacity(0.95),
    fontSize: 14,
  );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(loveLetterPasscodeControllerProvider);
    final s = async.value;

    final opening = s?.opening == true;
    final saving = s?.saving == true;
    final mode = s?.mode ?? LovePassMode.none;
    final noteId = widget.noteId;

    final canNext = (noteId != null) && _canNext(mode);

    final theme = ref.read(appThemeProvider);
    final palette = theme.loveLetter;
    final on = palette.onPrimary;

    return PopScope(
      canPop: !saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await ref.read(loveLetterPasscodeControllerProvider.notifier).saveNow();
        if (!context.mounted) return;
        Navigator.of(context).pop(result);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Protect Your Letter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: on,
            ),
          ),
          iconTheme: IconThemeData(color: on),
          centerTitle: false,
          actions: [
            TextButton(
              onPressed: (!canNext || saving)
                  ? null
                  : () async {
                      await ref
                          .read(loveLetterPasscodeControllerProvider.notifier)
                          .saveNow();
                      if (!context.mounted) return;
                      Navigator.pushNamed(
                        context,
                        LoveRoutePaths.preview,
                        arguments: {'noteId': noteId},
                      );
                    },
              child: saving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: on,
                      ),
                    )
                  : Text(
                      'Next',
                      style: TextStyle(
                        color: canNext ? on : on.withOpacity(0.45),
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
              padding: const EdgeInsets.all(16),
              child: opening
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        if ((s?.error ?? '').isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.error.withOpacity(0.35),
                              ),
                            ),
                            child: Text(s!.error!, style: TextStyle(color: on)),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          'How should they unlock it?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: on,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a little secret just for them.',
                          style: TextStyle(color: on.withOpacity(0.65)),
                        ),
                        const SizedBox(height: 16),

                        _ModeTile(
                          selected: mode == LovePassMode.none,
                          title: 'No Protection',
                          subtitle: 'They can read it right away',
                          icon: Icons.lock_open_rounded,
                          onTap: () {
                            ref
                                .read(
                                  loveLetterPasscodeControllerProvider.notifier,
                                )
                                .setMode(LovePassMode.none);
                            _passCtl.clear();
                            _pass2Ctl.clear();
                            _qCtl.clear();
                            _aCtl.clear();
                            _a2Ctl.clear();
                          },
                        ),
                        const SizedBox(height: 12),

                        _ModeTile(
                          selected: mode == LovePassMode.passcode,
                          title: 'Simple Passcode',
                          subtitle: 'A short code only they know',
                          icon: Icons.lock_rounded,
                          onTap: () {
                            ref
                                .read(
                                  loveLetterPasscodeControllerProvider.notifier,
                                )
                                .setMode(LovePassMode.passcode);
                            _qCtl.clear();
                            _aCtl.clear();
                            _a2Ctl.clear();
                          },
                          expanded: mode == LovePassMode.passcode
                              ? Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _passCtl,
                                      obscureText: !_showPass,
                                      style: _inputStyle(theme),
                                      cursorColor: on,
                                      decoration: _decor(
                                        theme,
                                        label: 'Passcode',
                                        helper: _passCtl.text.trim().isEmpty
                                            ? 'Keep it simple — a word or number they’ll remember'
                                            : (_isPassOk
                                                  ? 'Perfect match!'
                                                  : 'Passcodes do not match'),
                                        suffix: IconButton(
                                          onPressed: () => setState(
                                            () => _showPass = !_showPass,
                                          ),
                                          icon: Icon(
                                            _showPass
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: on.withOpacity(0.75),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _pass2Ctl,
                                      obscureText: !_showPass,
                                      style: _inputStyle(theme),
                                      cursorColor: on,
                                      decoration: _decor(
                                        theme,
                                        label: 'Confirm Passcode',
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),

                        _ModeTile(
                          selected: mode == LovePassMode.qa,
                          title: 'Question & Answer',
                          subtitle: 'A secret question only they can answer',
                          icon: Icons.quiz_rounded,
                          onTap: () {
                            ref
                                .read(
                                  loveLetterPasscodeControllerProvider.notifier,
                                )
                                .setMode(LovePassMode.qa);
                            _passCtl.clear();
                            _pass2Ctl.clear();
                          },
                          expanded: mode == LovePassMode.qa
                              ? Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _qCtl,
                                      style: _inputStyle(theme),
                                      cursorColor: on,
                                      decoration: _decor(
                                        theme,
                                        label: 'Question',
                                        hint: 'e.g. Where did we first meet?',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _aCtl,
                                      obscureText: !_showAnswer,
                                      style: _inputStyle(theme),
                                      cursorColor: on,
                                      decoration: _decor(
                                        theme,
                                        label: 'Answer',
                                        suffix: IconButton(
                                          onPressed: () => setState(
                                            () => _showAnswer = !_showAnswer,
                                          ),
                                          icon: Icon(
                                            _showAnswer
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: on.withOpacity(0.75),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _a2Ctl,
                                      obscureText: !_showAnswer,
                                      style: _inputStyle(theme),
                                      cursorColor: on,
                                      decoration: _decor(
                                        theme,
                                        label: 'Confirm Answer',
                                        helper:
                                            _qCtl.text.trim().isEmpty &&
                                                _aCtl.text.trim().isEmpty
                                            ? 'Tip: one word or short phrase works best'
                                            : (_isQaOk
                                                  ? 'Perfect match!'
                                                  : 'Answers do not match'),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Note: This info is stored on your device.',
                                      style: TextStyle(
                                        color: on.withOpacity(0.60),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends ConsumerWidget {
  const _ModeTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.expanded,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(appThemeProvider);
    final palette = theme.loveLetter;
    final on = palette.onPrimary;

    final border = selected ? on.withOpacity(0.55) : on.withOpacity(0.18);
    final bg = selected ? on.withOpacity(0.12) : Colors.white.withOpacity(0.04);

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
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: selected ? on.withOpacity(0.95) : on.withOpacity(0.65),
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
                          color: on,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: on.withOpacity(0.65)),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.chevron_right_rounded,
                  color: selected ? on.withOpacity(0.95) : on.withOpacity(0.55),
                  size: 26,
                ),
              ],
            ),
            if (selected && expanded != null) expanded!,
          ],
        ),
      ),
    );
  }
}
