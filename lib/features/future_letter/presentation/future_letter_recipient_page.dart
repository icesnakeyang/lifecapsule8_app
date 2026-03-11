import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/app_theme.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/application/future_letter_draft_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/future_letter_route_paths.dart';

class FutureLetterRecipientPage extends ConsumerStatefulWidget {
  final String noteId;

  const FutureLetterRecipientPage({super.key, required this.noteId});

  @override
  ConsumerState<FutureLetterRecipientPage> createState() =>
      _FutureLetterRecipientPageState();
}

class _FutureLetterRecipientPageState
    extends ConsumerState<FutureLetterRecipientPage> {
  final _userCodeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _toNameCtrl = TextEditingController();
  final _fromNameCtrl = TextEditingController();

  final _userCodeFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _toNameFocus = FocusNode();
  final _fromNameFocus = FocusNode();

  final _scrollCtrl = ScrollController();

  bool _hydrated = false;

  @override
  void initState() {
    super.initState();

    _userCodeCtrl.addListener(_syncRecipientToDraft);
    _emailCtrl.addListener(_syncRecipientToDraft);
    _toNameCtrl.addListener(_syncRecipientToDraft);
    _fromNameCtrl.addListener(_syncRecipientToDraft);
  }

  void _syncRecipientToDraft() {
    if (!_hydrated) return;

    ref
        .read(futureLetterDraftControllerProvider(widget.noteId).notifier)
        .setRecipient(
          userCode: _userCodeCtrl.text,
          email: _emailCtrl.text,
          toName: _toNameCtrl.text,
          fromName: _fromNameCtrl.text,
        );

    if (mounted) {
      setState(() {});
    }
  }

  void _applyHydrateOnce(FutureLetterDraftState state) {
    if (_hydrated) return;
    if (state.loading) return;

    final d = state.draft;
    _userCodeCtrl.text = d.userCode ?? '';
    _emailCtrl.text = d.email ?? '';
    _toNameCtrl.text = d.toName ?? '';
    _fromNameCtrl.text = d.fromName ?? '';
    _hydrated = true;
  }

  @override
  void dispose() {
    _userCodeCtrl.removeListener(_syncRecipientToDraft);
    _emailCtrl.removeListener(_syncRecipientToDraft);
    _toNameCtrl.removeListener(_syncRecipientToDraft);
    _fromNameCtrl.removeListener(_syncRecipientToDraft);

    _scrollCtrl.dispose();
    _userCodeCtrl.dispose();
    _emailCtrl.dispose();
    _toNameCtrl.dispose();
    _fromNameCtrl.dispose();
    _userCodeFocus.dispose();
    _emailFocus.dispose();
    _toNameFocus.dispose();
    _fromNameFocus.dispose();
    super.dispose();
  }

  Future<void> _persistOnExitOrNext() async {
    final controller = ref.read(
      futureLetterDraftControllerProvider(widget.noteId).notifier,
    );

    controller.setRecipient(
      userCode: _userCodeCtrl.text,
      email: _emailCtrl.text,
      toName: _toNameCtrl.text,
      fromName: _fromNameCtrl.text,
    );

    await controller.persist();
  }

  Future<void> _ensureVisible(FocusNode node) async {
    if (!node.hasFocus) return;
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    final ctx = node.context;
    if (ctx == null) return;
    try {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.15,
      );
    } catch (_) {}
  }

  InputDecoration _dec({
    required AppTheme theme,
    required String label,
    String? hint,
  }) {
    final palette = theme.future;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: palette.onPrimary.withValues(alpha: 0.7)),
      hintText: hint,
      hintStyle: TextStyle(color: palette.onPrimary.withValues(alpha: 0.45)),
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: palette.accent.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.accent.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.accent, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    final state = ref.watch(futureLetterDraftControllerProvider(widget.noteId));

    if (!state.loading) {
      _applyHydrateOnce(state);
    }

    final hasRecipient =
        _userCodeCtrl.text.trim().isNotEmpty ||
        _emailCtrl.text.trim().isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _persistOnExitOrNext();
        if (context.mounted) Navigator.of(context).pop(result);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        extendBody: true,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Recipient',
            style: TextStyle(
              color: theme.future.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.future.onPrimary),
            onPressed: () async {
              await _persistOnExitOrNext();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Hide keyboard',
              onPressed: () => FocusScope.of(context).unfocus(),
              icon: Icon(
                Icons.keyboard_hide,
                color: theme.future.accent,
                size: 24,
              ),
            ),
            TextButton(
              onPressed: hasRecipient && !state.loading && !state.saving
                  ? () async {
                      await _persistOnExitOrNext();
                      if (!context.mounted) return;
                      Navigator.pushNamed(
                        context,
                        FutureLetterRoutePaths.preview,
                        arguments: {'noteId': widget.noteId},
                      );
                    }
                  : null,
              child: state.saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Next',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.future.onPrimary,
                        fontSize: 16,
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
              colors: [theme.future.gradientStart, theme.future.gradientEnd],
            ),
          ),
          child: SizedBox.expand(
            child: SafeArea(
              bottom: true,
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: SingleChildScrollView(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (state.error != null &&
                                  state.error!.trim().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: theme.error.withValues(alpha: 0.85),
                                  ),
                                  child: Text(
                                    state.error!,
                                    style: TextStyle(color: theme.onError),
                                  ),
                                ),

                              TextField(
                                controller: _userCodeCtrl,
                                focusNode: _userCodeFocus,
                                style: TextStyle(color: theme.future.onPrimary),
                                decoration: _dec(
                                  theme: theme,
                                  label: 'User code (optional)',
                                  hint: 'e.g. LC-123456',
                                ),
                                onTap: () => _ensureVisible(_userCodeFocus),
                              ),
                              const SizedBox(height: 16),

                              TextField(
                                controller: _emailCtrl,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: theme.future.onPrimary),
                                decoration: _dec(
                                  theme: theme,
                                  label: 'Email (optional)',
                                  hint: 'name@example.com',
                                ),
                                onTap: () => _ensureVisible(_emailFocus),
                              ),

                              const SizedBox(height: 12),
                              Text(
                                'You can fill either one — or both. We’ll decide delivery on the server.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.future.onPrimary.withValues(
                                    alpha: 0.75,
                                  ),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),

                              TextField(
                                controller: _toNameCtrl,
                                focusNode: _toNameFocus,
                                style: TextStyle(color: theme.future.onPrimary),
                                decoration: _dec(
                                  theme: theme,
                                  label: 'To name (optional)',
                                ),
                                onTap: () => _ensureVisible(_toNameFocus),
                              ),
                              const SizedBox(height: 16),

                              TextField(
                                controller: _fromNameCtrl,
                                focusNode: _fromNameFocus,
                                style: TextStyle(color: theme.future.onPrimary),
                                decoration: _dec(
                                  theme: theme,
                                  label: 'From name (optional)',
                                ),
                                onTap: () => _ensureVisible(_fromNameFocus),
                              ),
                            ],
                          ),
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
