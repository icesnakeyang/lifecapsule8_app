// love_letter_recipient.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/love_letter/love_letter_provider.dart';

class LoveLetterRecipient extends ConsumerStatefulWidget {
  const LoveLetterRecipient({super.key});

  @override
  ConsumerState<LoveLetterRecipient> createState() =>
      _LoveLetterRecipientState();
}

class _LoveLetterRecipientState extends ConsumerState<LoveLetterRecipient> {
  bool _didInit = false;
  String? _noteId;
  // mode
  String _toType = 'USER'; // USER | EMAIL

  // userCode path
  String _userCode = '';
  String? _nickname;

  final _emailCtl = TextEditingController();
  final _toNameCtl = TextEditingController();
  final _fromNameCtl = TextEditingController();

  Timer? _debounce;

  bool get _canNext {
    final hasTo =
        (_toType == 'USER' && (_nickname?.isNotEmpty ?? false)) ||
        (_toType == 'EMAIL' && _emailCtl.text.trim().isNotEmpty);
    final hasNames =
        _toNameCtl.text.trim().isNotEmpty &&
        _fromNameCtl.text.trim().isNotEmpty;
    return hasTo && hasNames;
  }

  void _scheduleSave() {
    final noteId = _noteId;
    if (noteId == null) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final emailText = _emailCtl.text.trim();
      final toNameText = _toNameCtl.text.trim();
      final fromNameText = _fromNameCtl.text.trim();
      await ref
          .read(loveLetterProvider.notifier)
          .saveRecipient(
            noteId: noteId,
            toType: _toType,
            userCode: _toType == 'USER'
                ? (_userCode.isEmpty ? null : _userCode)
                : null,
            nickname: _toType == 'USER' ? _nickname : null,
            email: _toType == 'EMAIL' ? emailText : null,
            toName: toNameText,
            fromName: fromNameText,
            clearEmail: _toType == 'EMAIL' && emailText.isEmpty,
            clearToName: toNameText.isEmpty,
            clearFromName: fromNameText.isEmpty,
          );
    });
  }

  Future<void> _forceSaveNow() async {
    final noteId = _noteId;
    if (noteId == null) return;
    _debounce?.cancel();

    await ref
        .read(loveLetterProvider.notifier)
        .saveRecipient(
          noteId: noteId,
          toType: _toType,
          userCode: _toType == 'USER'
              ? (_userCode.isEmpty ? null : _userCode)
              : null,
          nickname: _toType == 'USER' ? _nickname : null,
          email: _toType == 'EMAIL'
              ? (_emailCtl.text.trim().isEmpty ? null : _emailCtl.text.trim())
              : null,
          toName: _toNameCtl.text.trim().isEmpty
              ? null
              : _toNameCtl.text.trim(),
          fromName: _fromNameCtl.text.trim().isEmpty
              ? null
              : _fromNameCtl.text.trim(),
        );
  }

  Future<void> _pickUserByCode() async {
    final res = await Navigator.pushNamed(context, '/LoveLetterUserSearch');
    if (!mounted) return;
    if (res is Map) {
      setState(() {
        _toType = 'USER';
        _userCode = (res['userCode'] as String?) ?? '';
        _nickname = (res['nickname'] as String?) ?? '';
        _emailCtl.text = '';
      });
      _scheduleSave();
    }
  }

  @override
  void initState() {
    super.initState();

    void onChanged() {
      setState(() {});
      _scheduleSave();
    }

    _emailCtl.addListener(onChanged);
    _toNameCtl.addListener(onChanged);
    _fromNameCtl.addListener(onChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final noteId = args?['noteId'] as String?;
    if (noteId == null) return;
    _noteId = noteId;

    // ✅ 首次进入：确保草稿存在 + 从 Hive 回填
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(loveLetterProvider.notifier).ensureDraft(noteId);
      if (!mounted) return;

      final d = ref.read(loveLetterProvider.notifier).getDraft(noteId);
      if (d == null) return;

      setState(() {
        _toType = d.toType ?? 'USER';
        _userCode = d.userCode ?? '';
        _nickname = d.nickname;

        _emailCtl.text = d.email ?? '';
        _toNameCtl.text = d.toName ?? '';
        _fromNameCtl.text = d.fromName ?? '';
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _emailCtl.dispose();
    _toNameCtl.dispose();
    _fromNameCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noteId = _noteId;

    return Scaffold(
      appBar: AppBar(title: const Text('I will tell you')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Who is this for?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'USER',
                    label: Text('LifeCapsule User'),
                    icon: Icon(Icons.verified_user),
                  ),
                  ButtonSegment(
                    value: 'EMAIL',
                    label: Text('Email'),
                    icon: Icon(Icons.mail),
                  ),
                ],
                selected: {_toType},
                onSelectionChanged: (s) {
                  setState(() => _toType = s.first);
                  _scheduleSave();
                },
              ),

              const SizedBox(height: 12),

              if (_toType == 'USER') ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: noteId == null ? null : _pickUserByCode,
                    child: const Text('Find by userCode'),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (_nickname?.isNotEmpty ?? false)
                              ? 'Selected: ${_nickname!}'
                              : 'No user selected',
                        ),
                      ),
                      if (_userCode.isNotEmpty)
                        Text(
                          '($_userCode)',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'To Email',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'someone@email.com',
                    hintStyle: TextStyle(color: Color(0xFF757575)),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Text(
                'To name',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _toNameCtl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'How you call them',
                  hintStyle: TextStyle(color: Color(0xFF757575)),
                ),
              ),

              const SizedBox(height: 12),
              const Text('From', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _fromNameCtl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Your signature',
                  hintStyle: TextStyle(color: Color(0xFF757575)),
                ),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (noteId == null || !_canNext)
                      ? null
                      : () async {
                          await _forceSaveNow();
                          if (!context.mounted) return;
                          Navigator.pushNamed(
                            context,
                            '/LoveLetterSendSpectime',
                            arguments: {'noteId': noteId},
                          );
                        },
                  child: const Text('Next: choose when'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
