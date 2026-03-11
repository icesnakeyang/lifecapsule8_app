import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/last_wishes/application/controllers/last_wishes_controller.dart';
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_route_paths.dart';

class LastWishesRecipientPage extends ConsumerStatefulWidget {
  final String? noteId;

  const LastWishesRecipientPage({super.key, this.noteId});

  @override
  ConsumerState<LastWishesRecipientPage> createState() =>
      _LastWishesRecipientPageState();
}

class _LastWishesRecipientPageState
    extends ConsumerState<LastWishesRecipientPage> {
  final _emailCtrl = TextEditingController();
  final _email2Ctrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController();

  String? _resolvedNoteId;
  bool _listenersBound = false;

  String? _lastEmail;
  String? _lastConfirmEmail;
  String? _lastMessageNote;
  String? _lastYearsText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_resolvedNoteId != null) return;

    String? noteId = widget.noteId;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (noteId == null && args is Map) {
      noteId = args['noteId'] as String?;
    }

    _resolvedNoteId = (noteId == null || noteId.trim().isEmpty)
        ? 'last_wishes'
        : noteId.trim();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _email2Ctrl.dispose();
    _noteCtrl.dispose();
    _yearsCtrl.dispose();
    super.dispose();
  }

  void _bindListenersIfNeeded() {
    if (_listenersBound) return;
    _listenersBound = true;

    _emailCtrl.addListener(_onEmailChanged);
    _email2Ctrl.addListener(_onConfirmEmailChanged);
    _noteCtrl.addListener(_onNoteChanged);
    _yearsCtrl.addListener(_onYearsChanged);
  }

  void _onEmailChanged() {
    final noteId = _resolvedNoteId;
    if (noteId == null) return;

    final text = _emailCtrl.text;
    if (_lastEmail == text) return;
    _lastEmail = text;

    ref.read(lastWishesControllerProvider(noteId).notifier).setEmail(text);
  }

  void _onConfirmEmailChanged() {
    final noteId = _resolvedNoteId;
    if (noteId == null) return;

    final text = _email2Ctrl.text;
    if (_lastConfirmEmail == text) return;
    _lastConfirmEmail = text;

    ref
        .read(lastWishesControllerProvider(noteId).notifier)
        .setConfirmEmail(text);
  }

  void _onNoteChanged() {
    final noteId = _resolvedNoteId;
    if (noteId == null) return;

    final text = _noteCtrl.text;
    if (_lastMessageNote == text) return;
    _lastMessageNote = text;

    ref
        .read(lastWishesControllerProvider(noteId).notifier)
        .setMessageNote(text);
  }

  void _onYearsChanged() {
    final noteId = _resolvedNoteId;
    if (noteId == null) return;

    final text = _yearsCtrl.text.trim();
    if (_lastYearsText == text) return;
    _lastYearsText = text;

    final years = int.tryParse(text);
    ref
        .read(lastWishesControllerProvider(noteId).notifier)
        .setWaitingYears(years);
  }

  void _hydrateIfNeeded(LastWishesState s) {
    _bindListenersIfNeeded();

    if (_lastEmail != s.email) {
      _lastEmail = s.email;
      _emailCtrl.value = TextEditingValue(
        text: s.email,
        selection: TextSelection.collapsed(offset: s.email.length),
      );
    }

    if (_lastConfirmEmail != s.confirmEmail) {
      _lastConfirmEmail = s.confirmEmail;
      _email2Ctrl.value = TextEditingValue(
        text: s.confirmEmail,
        selection: TextSelection.collapsed(offset: s.confirmEmail.length),
      );
    }

    if (_lastMessageNote != s.messageNote) {
      _lastMessageNote = s.messageNote;
      _noteCtrl.value = TextEditingValue(
        text: s.messageNote,
        selection: TextSelection.collapsed(offset: s.messageNote.length),
      );
    }

    final yearsText = s.waitingYears?.toString() ?? '';
    if (_lastYearsText != yearsText) {
      _lastYearsText = yearsText;
      _yearsCtrl.value = TextEditingValue(
        text: yearsText,
        selection: TextSelection.collapsed(offset: yearsText.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteId = _resolvedNoteId ?? 'last_wishes';
    final asyncState = ref.watch(lastWishesControllerProvider(noteId));
    final notifier = ref.read(lastWishesControllerProvider(noteId).notifier);
    final theme = ref.read(appThemeProvider);
    final palette = theme.wishes;

    return asyncState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Recipient')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (s) {
        _hydrateIfNeeded(s);

        final email1 = _emailCtrl.text.trim();
        final email2 = _email2Ctrl.text.trim();
        final emailsMatch = email1.isNotEmpty && email1 == email2;
        final emailOk = notifier.isValidEmail(email1) && emailsMatch;
        final yearsOk = s.waitingYears != null && s.waitingYears! > 0;
        final canNextLocal = emailOk && yearsOk;

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text(
              'Recipient',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () async {
                await notifier.saveNow();
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.gradientStart, palette.gradientEnd],
                ),
              ),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    if (s.error != null && s.error!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          s.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    const Text(
                      'Recipient Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'name@example.com',
                        border: OutlineInputBorder(),
                        fillColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _email2Ctrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        fillColor: Colors.transparent,
                        labelText: 'Confirm Email',
                        hintText: 'Re-enter the same email',
                        border: const OutlineInputBorder(),
                        helperText: email1.isEmpty
                            ? 'Please enter the same email twice.'
                            : (emailsMatch
                                  ? 'Emails match'
                                  : 'Emails do not match'),
                        helperStyle: TextStyle(
                          color: emailsMatch ? theme.success : theme.error,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    if (email1.isNotEmpty && !emailOk)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Please enter a valid email twice.',
                          style: TextStyle(
                            color: palette.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    const Text(
                      'Waiting Period',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how long we should wait before we ask you to confirm delivery.',
                      style: TextStyle(
                        fontSize: 14,
                        color: palette.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final y in const [1, 5, 10, 20])
                          ChoiceChip(
                            selected: s.waitingYears == y,
                            label: Text(
                              '$y year${y == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onSelected: (_) => notifier.setWaitingYears(y),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.10,
                            ),
                            selectedColor: palette.accent.withValues(
                              alpha: 0.9,
                            ),
                            side: BorderSide(
                              color: s.waitingYears == y
                                  ? palette.accent
                                  : palette.onPrimary.withValues(alpha: 0.15),
                            ),
                            labelStyle: TextStyle(
                              color: s.waitingYears == y
                                  ? palette.onPrimary
                                  : palette.onPrimary.withValues(alpha: 0.9),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Custom years',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _yearsCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: palette.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter number of years',
                        hintStyle: TextStyle(
                          color: palette.onPrimary.withValues(alpha: 0.45),
                        ),
                        suffixText: 'years',
                        suffixStyle: TextStyle(
                          color: palette.onPrimary.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: palette.onPrimary.withValues(alpha: 0.12),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: palette.onPrimary.withValues(alpha: 0.12),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: palette.accent),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'You can choose any positive number, such as 2, 7, 15, or 30.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: palette.onPrimary.withValues(alpha: 0.7),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Message Note (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _noteCtrl,
                      maxLines: 4,
                      minLines: 3,
                      decoration: const InputDecoration(
                        fillColor: Colors.transparent,
                        hintText:
                            'A short note to help the recipient understand.',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (s.saving)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: palette.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Saving...',
                              style: TextStyle(
                                color: palette.onPrimary.withValues(
                                  alpha: 0.75,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: canNextLocal
                              ? palette.accent
                              : palette.accent.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: FilledButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            shadowColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            overlayColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (!canNextLocal) return Colors.transparent;
                              return palette.onPrimary.withValues(alpha: 0.12);
                            }),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                          onPressed: canNextLocal
                              ? () async {
                                  await notifier.saveNow();
                                  if (!context.mounted) return;

                                  Navigator.pushNamed(
                                    context,
                                    LastWishesRoutePaths.preview,
                                    arguments: {'noteId': noteId},
                                  );
                                }
                              : null,
                          child: Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: canNextLocal
                                  ? palette.onPrimary
                                  : palette.onPrimary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
