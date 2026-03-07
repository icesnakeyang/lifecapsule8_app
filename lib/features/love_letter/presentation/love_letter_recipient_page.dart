// lib/features/love_letter/presentation/love_letter_recipient_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/app_theme.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';

import 'package:lifecapsule8_app/features/love_letter/application/love_letter_recipient_controller.dart';
import 'package:lifecapsule8_app/features/love_letter/love_route_paths.dart';

class LoveLetterRecipientPage extends ConsumerStatefulWidget {
  final String? noteId;
  const LoveLetterRecipientPage({super.key, this.noteId});

  @override
  ConsumerState<LoveLetterRecipientPage> createState() =>
      _LoveLetterRecipientPageState();
}

class _LoveLetterRecipientPageState
    extends ConsumerState<LoveLetterRecipientPage> {
  final _emailCtl = TextEditingController();
  final _toNameCtl = TextEditingController();
  final _fromNameCtl = TextEditingController();

  bool _hydrated = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final noteId = widget.noteId;
      if (noteId == null || noteId.trim().isEmpty) return;

      await ref
          .read(loveLetterRecipientControllerProvider.notifier)
          .open(noteId: noteId);

      final s = ref.read(loveLetterRecipientControllerProvider).value;
      final meta = s?.meta;

      _emailCtl.text = (meta?.email ?? '');
      _toNameCtl.text = (meta?.toName ?? '');
      _fromNameCtl.text = (meta?.fromName ?? '');

      if (!mounted) return;
      setState(() => _hydrated = true);
    });

    void onChanged() {
      if (!_hydrated) return;
      ref
          .read(loveLetterRecipientControllerProvider.notifier)
          .updateLocal(
            email: _emailCtl.text,
            toName: _toNameCtl.text,
            fromName: _fromNameCtl.text,
          );
    }

    _emailCtl.addListener(onChanged);
    _toNameCtl.addListener(onChanged);
    _fromNameCtl.addListener(onChanged);
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _toNameCtl.dispose();
    _fromNameCtl.dispose();
    super.dispose();
  }

  // ====== theme helpers (ONLY from appThemeProvider) ======

  Color _fieldFillColor(AppTheme theme) => Colors.white.withOpacity(0.10);

  Color _fieldBorderColor(AppTheme theme) =>
      theme.loveLetter.onPrimary.withOpacity(0.22);

  Color _fieldFocusBorderColor(AppTheme theme) =>
      theme.loveLetter.onPrimary.withOpacity(0.55);

  Color _labelColor(AppTheme theme) =>
      theme.loveLetter.onPrimary.withOpacity(0.85);

  Color _hintColor(AppTheme theme) =>
      theme.loveLetter.onPrimary.withOpacity(0.55);

  TextStyle _inputTextStyle(AppTheme theme) => TextStyle(
    color: theme.loveLetter.onPrimary.withOpacity(0.95),
    fontSize: 14,
  );

  TextStyle _labelStyle(AppTheme theme) =>
      TextStyle(color: _labelColor(theme), fontWeight: FontWeight.w600);

  TextStyle _hintStyle(AppTheme theme) => TextStyle(color: _hintColor(theme));

  InputDecoration _decor(
    AppTheme theme, {
    required String label,
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              color: theme.loveLetter.onPrimary.withOpacity(0.8),
            ),
      filled: true,
      fillColor: _fieldFillColor(theme),
      labelStyle: _labelStyle(theme),
      hintStyle: _hintStyle(theme),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _fieldBorderColor(theme)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _fieldFocusBorderColor(theme),
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.error, width: 1.6),
      ),
    );
  }

  ButtonStyle _segStyle(AppTheme theme) {
    final on = theme.loveLetter.onPrimary;
    return ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        final c = on.withOpacity(
          states.contains(WidgetState.selected) ? 0.55 : 0.22,
        );
        return BorderSide(color: c, width: 1.2);
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return on.withOpacity(0.18);
        return Colors.white.withOpacity(0.06);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return on.withOpacity(0.98);
        return on.withOpacity(0.78);
      }),
      overlayColor: WidgetStateProperty.all(on.withOpacity(0.10)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  ButtonStyle _outlinedBtnStyle(AppTheme theme) {
    final on = theme.loveLetter.onPrimary;
    return ButtonStyle(
      side: WidgetStateProperty.all(
        BorderSide(color: on.withOpacity(0.22), width: 1.2),
      ),
      foregroundColor: WidgetStateProperty.all(on.withOpacity(0.95)),
      backgroundColor: WidgetStateProperty.all(Colors.white.withOpacity(0.06)),
      overlayColor: WidgetStateProperty.all(on.withOpacity(0.10)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(loveLetterRecipientControllerProvider);
    final s = async.value;

    final opening = s?.opening == true;
    final saving = s?.saving == true;

    final theme = ref.read(appThemeProvider);
    final palette = theme.loveLetter;
    final noteId = widget.noteId;

    return PopScope(
      canPop: !saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await ref.read(loveLetterRecipientControllerProvider.notifier).save();
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
            'Recipient',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: palette.onPrimary,
            ),
          ),
          iconTheme: IconThemeData(color: palette.onPrimary),
          centerTitle: false,
          actions: [
            TextButton(
              onPressed: (saving || noteId == null)
                  ? null
                  : () async {
                      await ref
                          .read(loveLetterRecipientControllerProvider.notifier)
                          .save();
                      if (!context.mounted) return;
                      Navigator.pushNamed(
                        context,
                        LoveRoutePaths.sendTime,
                        arguments: {'noteId': noteId},
                      );
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        color: palette.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
        body: opening
            ? const Center(child: CircularProgressIndicator())
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [palette.gradientStart, palette.gradientEnd],
                  ),
                ),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bottomInset = MediaQuery.of(
                        context,
                      ).viewInsets.bottom;
                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          16 + bottomInset,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((s?.error ?? '').isNotEmpty) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.error,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      s!.error!,
                                      style: TextStyle(color: theme.onError),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                Text(
                                  'Who is this letter for?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: palette.onPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // ✅ SegmentedButton themed by appThemeProvider
                                SegmentedButton<String>(
                                  style: _segStyle(theme),
                                  segments: const [
                                    ButtonSegment(
                                      value: 'USER',
                                      label: Text('LifeCapsule'),
                                      icon: Icon(Icons.people),
                                    ),
                                    ButtonSegment(
                                      value: 'EMAIL',
                                      label: Text('Email'),
                                      icon: Icon(Icons.email),
                                    ),
                                  ],
                                  selected: {s?.meta.toType ?? 'USER'},
                                  onSelectionChanged: (set) {
                                    final v = set.first;
                                    ref
                                        .read(
                                          loveLetterRecipientControllerProvider
                                              .notifier,
                                        )
                                        .setToType(v);
                                  },
                                ),

                                const SizedBox(height: 16),

                                if ((s?.meta.toType ?? 'USER') == 'USER') ...[
                                  OutlinedButton.icon(
                                    style: _outlinedBtnStyle(theme),
                                    onPressed: () async {
                                      final res = await Navigator.pushNamed(
                                        context,
                                        '/LoveLetterUserSearch',
                                      );
                                      if (!mounted) return;
                                      if (res is Map) {
                                        ref
                                            .read(
                                              loveLetterRecipientControllerProvider
                                                  .notifier,
                                            )
                                            .selectUser(
                                              userCode:
                                                  (res['userCode']
                                                      as String?) ??
                                                  '',
                                              nickname:
                                                  (res['nickname']
                                                      as String?) ??
                                                  '',
                                              userId:
                                                  (res['userId'] as String?) ??
                                                  '',
                                            );
                                      }
                                    },
                                    icon: Icon(
                                      Icons.search,
                                      color: palette.onPrimary.withOpacity(0.9),
                                    ),
                                    label: Text(
                                      'Find by userCode',
                                      style: TextStyle(
                                        color: palette.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _SelectedUserCard(
                                    nickname: s?.meta.nickname,
                                    userCode: s?.meta.userCode,
                                    theme: theme,
                                  ),
                                ] else ...[
                                  TextField(
                                    controller: _emailCtl,
                                    keyboardType: TextInputType.emailAddress,
                                    style: _inputTextStyle(theme),
                                    cursorColor: palette.onPrimary,
                                    decoration: _decor(
                                      theme,
                                      label: 'Recipient email',
                                      hint: 'someone@email.com',
                                      prefixIcon: Icons.email,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),

                                TextField(
                                  controller: _toNameCtl,
                                  style: _inputTextStyle(theme),
                                  cursorColor: palette.onPrimary,
                                  decoration: _decor(
                                    theme,
                                    label: 'To (how they call them)',
                                    hint: 'Darling / My love / [Name]',
                                    prefixIcon: Icons.favorite,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                TextField(
                                  controller: _fromNameCtl,
                                  style: _inputTextStyle(theme),
                                  cursorColor: palette.onPrimary,
                                  decoration: _decor(
                                    theme,
                                    label: 'From (your signature)',
                                    hint: 'Yours / [Your name]',
                                    prefixIcon: Icons.edit,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                _HintText(
                                  ok: s?.canNext == true,
                                  text: (s?.canNext == true)
                                      ? 'Looks good. Tap Next.'
                                      : 'Please choose a recipient and fill To/From.',
                                  theme: theme,
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

class _SelectedUserCard extends StatelessWidget {
  final String? nickname;
  final String? userCode;
  final AppTheme theme;

  const _SelectedUserCard({this.nickname, this.userCode, required this.theme});

  @override
  Widget build(BuildContext context) {
    final on = theme.loveLetter.onPrimary;
    final has = (nickname ?? '').trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: on.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(
            has ? Icons.check_circle : Icons.info_outline,
            color: has
                ? Colors.greenAccent.withOpacity(0.95)
                : on.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              has ? 'Selected: $nickname' : 'No recipient selected yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: on.withOpacity(0.92)),
            ),
          ),
          if ((userCode ?? '').trim().isNotEmpty)
            Text('($userCode)', style: TextStyle(color: on.withOpacity(0.7))),
        ],
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  final bool ok;
  final String text;
  final AppTheme theme;

  const _HintText({required this.ok, required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: ok ? theme.loveLetter.onPrimary : theme.loveLetter.primary,
        fontWeight: ok ? FontWeight.w700 : FontWeight.w600,
      ),
    );
  }
}
