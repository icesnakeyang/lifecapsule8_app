// lib/pages/love_letter/love_letter_passcode.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/love_letter/love_letter_provider.dart';

enum _PassMode { none, passcode, qa }

class LoveLetterPasscode extends ConsumerStatefulWidget {
  const LoveLetterPasscode({super.key});

  @override
  ConsumerState<LoveLetterPasscode> createState() => _LoveLetterPasscodeState();
}

class _LoveLetterPasscodeState extends ConsumerState<LoveLetterPasscode> {
  bool _didInit = false;
  String? _noteId;

  _PassMode _mode = _PassMode.none;

  // PASSCODE
  final _passCtl = TextEditingController();
  final _pass2Ctl = TextEditingController();
  bool _showPass = false;

  // QA
  final _qCtl = TextEditingController();
  final _aCtl = TextEditingController();
  final _a2Ctl = TextEditingController();
  final _backupCtl = TextEditingController();
  bool _showAnswer = false;

  Timer? _debounce;

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

  bool get _canNext {
    switch (_mode) {
      case _PassMode.none:
        return true;
      case _PassMode.passcode:
        return _isPassOk;
      case _PassMode.qa:
        return _isQaOk;
    }
  }

  void _onAnyChanged() {
    setState(() {}); // 让 Next 立即刷新
    _scheduleSave();
  }

  void _scheduleSave() {
    final noteId = _noteId;
    if (noteId == null) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      await _saveNowInternal(noteId);
    });
  }

  Future<void> _saveNowInternal(String noteId) async {
    final notifier = ref.read(loveLetterProvider.notifier);

    switch (_mode) {
      case _PassMode.none:
        await notifier.savePasscode(
          noteId: noteId,
          mode: 'NONE',
          passcode: null,
          clearPasscode: true,
        );
        break;

      case _PassMode.passcode:
        final p1 = _passCtl.text.trim();
        final p2 = _pass2Ctl.text.trim();

        if (p1.isEmpty && p2.isEmpty) {
          await notifier.savePasscode(
            noteId: noteId,
            mode: 'PASSCODE',
            passcode: null,
            clearPasscode: true,
          );
          return;
        }

        await notifier.savePasscode(
          noteId: noteId,
          mode: 'PASSCODE',
          passcode: p1,
          clearPasscode: p1.isEmpty,
        );
        break;

      case _PassMode.qa:
        final q = _qCtl.text.trim();
        final a1 = _aCtl.text.trim();
        final a2 = _a2Ctl.text.trim();

        if (q.isEmpty && a1.isEmpty && a2.isEmpty) {
          await notifier.savePasscode(
            noteId: noteId,
            mode: 'QA',
            passcode: null,
            clearPasscode: true,
          );
          return;
        }

        // 未完成一致时，不落盘答案（避免半成品）
        if (q.isEmpty || a1.isEmpty || a1 != a2) {
          await notifier.savePasscode(
            noteId: noteId,
            mode: 'QA',
            passcode: null,
            clearPasscode: true,
          );
          return;
        }

        final payload = <String, dynamic>{'q': q, 'a': a1};

        await notifier.savePasscode(
          noteId: noteId,
          mode: 'QA',
          passcode: jsonEncode(payload),
          clearPasscode: false,
        );
        break;
    }
  }

  Future<void> _forceSaveNow() async {
    final noteId = _noteId;
    if (noteId == null) return;
    _debounce?.cancel();
    await _saveNowInternal(noteId);
  }

  void _setMode(_PassMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    // 切换模式时，清理非当前模式的输入（避免历史残留影响保存）
    if (mode != _PassMode.passcode) {
      _passCtl.clear();
      _pass2Ctl.clear();
    }
    if (mode != _PassMode.qa) {
      _qCtl.clear();
      _aCtl.clear();
      _a2Ctl.clear();
      _backupCtl.clear();
    }
    _scheduleSave();
  }

  @override
  void initState() {
    super.initState();

    _passCtl.addListener(_onAnyChanged);
    _pass2Ctl.addListener(_onAnyChanged);

    _qCtl.addListener(_onAnyChanged);
    _aCtl.addListener(_onAnyChanged);
    _a2Ctl.addListener(_onAnyChanged);
    _backupCtl.addListener(_onAnyChanged);
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await ref.read(loveLetterProvider.notifier).ensureDraft(noteId);
      if (!mounted) return;

      final d = ref.read(loveLetterProvider.notifier).getDraft(noteId);

      final m = (d?.passcodeMode ?? 'NONE').toUpperCase();
      if (m == 'PASSCODE') {
        _mode = _PassMode.passcode;
      } else if (m == 'QA') {
        _mode = _PassMode.qa;
      } else {
        _mode = _PassMode.none;
      }

      if (_mode == _PassMode.passcode) {
        final p = (d?.passcode ?? '');
        _passCtl.text = p;
        _pass2Ctl.text = p.isEmpty ? '' : p;
      }

      if (_mode == _PassMode.qa) {
        final raw = d?.passcode;
        if (raw != null && raw.trim().isNotEmpty) {
          try {
            final map = jsonDecode(raw) as Map<String, dynamic>;
            _qCtl.text = (map['q'] as String?) ?? '';
            final a = (map['a'] as String?) ?? '';
            _aCtl.text = a;
            _a2Ctl.text = a.isEmpty ? '' : a;
            _backupCtl.text = (map['backup'] as String?) ?? '';
          } catch (_) {}
        }
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _passCtl.dispose();
    _pass2Ctl.dispose();

    _qCtl.dispose();
    _aCtl.dispose();
    _a2Ctl.dispose();
    _backupCtl.dispose();

    super.dispose();
  }

  Widget _modeCard({
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? expanded,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? primary : Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: selected ? primary : Colors.grey.shade500),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                selected
                    ? Icon(Icons.check_circle, color: primary)
                    : const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            if (selected && expanded != null) ...[
              const SizedBox(height: 12),
              expanded,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noteId = _noteId;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Set Passcode')),

      // ✅ 只保留一个 Next：固定在底部
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (noteId == null || !_canNext)
                  ? null
                  : () async {
                      await _forceSaveNow();
                      if (!context.mounted) return;
                      Navigator.pushNamed(
                        context,
                        '/LoveLetterPreview',
                        arguments: {'noteId': noteId},
                      );
                    },
              child: const Text('Next'),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            return SingleChildScrollView(
              // ✅ 底部留空间，避免被 bottomNavigationBar 挡住
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight - 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How should they unlock it?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _modeCard(
                      selected: _mode == _PassMode.none,
                      onTap: () => _setMode(_PassMode.none),
                      icon: Icons.lock_open,
                      title: 'No passcode',
                      subtitle: 'They can read it immediately when it arrives.',
                    ),

                    const SizedBox(height: 10),

                    _modeCard(
                      selected: _mode == _PassMode.passcode,
                      onTap: () => _setMode(_PassMode.passcode),
                      icon: Icons.lock,
                      title: 'Simple passcode',
                      subtitle: 'They enter a short code to unlock.',
                      expanded: Column(
                        children: [
                          TextField(
                            controller: _passCtl,
                            obscureText: !_showPass,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Passcode',
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _showPass = !_showPass),
                                icon: Icon(
                                  _showPass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _pass2Ctl,
                            obscureText: !_showPass,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Confirm passcode',
                              helperText: _passCtl.text.trim().isEmpty
                                  ? 'Keep it simple — a short word or number works best.'
                                  : (_isPassOk
                                        ? 'Looks good.'
                                        : 'Passcodes do not match.'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    _modeCard(
                      selected: _mode == _PassMode.qa,
                      onTap: () => _setMode(_PassMode.qa),
                      icon: Icons.quiz,
                      title: 'Question & answer',
                      subtitle:
                          'They answer your question to unlock. (Fun & flirty)',
                      expanded: Column(
                        children: [
                          if (_mode == _PassMode.qa) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: _qCtl,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Question',
                                hintText: 'e.g. Where did we first meet?',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _aCtl,
                              obscureText: !_showAnswer,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Answer',
                                hintText: 'Keep it short and easy to type',
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _showAnswer = !_showAnswer,
                                  ),
                                  icon: Icon(
                                    _showAnswer
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _a2Ctl,
                              obscureText: !_showAnswer,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Confirm answer',
                                helperText:
                                    _qCtl.text.trim().isEmpty &&
                                        _aCtl.text.isEmpty
                                    ? 'Tip: one word or a short phrase works best.'
                                    : (_isQaOk
                                          ? 'Looks good.'
                                          : 'Answers do not match.'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // TextField(
                            //   controller: _backupCtl,
                            //   decoration: const InputDecoration(
                            //     border: OutlineInputBorder(),
                            //     labelText: 'Backup passcode (optional)',
                            //     hintText:
                            //         'If they forget, you can share this later',
                            //   ),
                            // ),
                            const SizedBox(height: 6),
                            const Text(
                              'Note: Answers are saved only on your device. The server does not know them.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
