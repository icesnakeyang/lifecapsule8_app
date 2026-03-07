import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';

import 'package:lifecapsule8_app/features/last_wishes/application/last_wishes_recipient_controller.dart';
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_route_paths.dart';

class LastWishesRecipientPage extends ConsumerStatefulWidget {
  const LastWishesRecipientPage({super.key});

  @override
  ConsumerState<LastWishesRecipientPage> createState() =>
      _LastWishesRecipientPageState();
}

class _LastWishesRecipientPageState
    extends ConsumerState<LastWishesRecipientPage> {
  final _emailCtrl = TextEditingController();
  final _email2Ctrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool _hydrated = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _email2Ctrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _hydrateIfNeeded(LastWishesRecipientState s) {
    if (_hydrated) return;
    if (s.loading) return;
    if (s.note == null) return;

    _hydrated = true;

    _emailCtrl.text = s.email;
    _email2Ctrl.text = s.confirmEmail;
    _noteCtrl.text = s.messageNote;

    _emailCtrl.addListener(() {
      ref
          .read(lastWishesRecipientControllerProvider.notifier)
          .setEmail(_emailCtrl.text);
    });
    _email2Ctrl.addListener(() {
      ref
          .read(lastWishesRecipientControllerProvider.notifier)
          .setConfirmEmail(_email2Ctrl.text);
    });
    _noteCtrl.addListener(() {
      ref
          .read(lastWishesRecipientControllerProvider.notifier)
          .setMessageNote(_noteCtrl.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(lastWishesRecipientControllerProvider);
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

        final notifier = ref.read(
          lastWishesRecipientControllerProvider.notifier,
        );

        final email1 = _emailCtrl.text.trim();
        final email2 = _email2Ctrl.text.trim();
        final emailsMatch = email1.isNotEmpty && email1 == email2;
        final emailOk = notifier.isValidEmail(email1) && emailsMatch;

        final canNextLocal = emailOk && ((s.waitingYears ?? 0) > 0);

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
          body: Container(
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
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.25)),
                      ),
                      child: Text(
                        s.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  const Text(
                    'Recipient Email',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Please enter a valid email twice.',
                        style: TextStyle(color: palette.primary, fontSize: 14),
                      ),
                    ),

                  const SizedBox(height: 20),
                  const Text(
                    'Waiting Period',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final y in const [1, 5, 10, 20])
                        ChoiceChip(
                          selected: s.waitingYears == y,
                          label: Text(
                            '$y year${y == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onSelected: (_) => notifier.setWaitingYears(y),
                          backgroundColor: palette.accent,
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Message Note (Optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

                                // 下一步：preview（你要我继续生成的话就接着来）
                                Navigator.pushNamed(
                                  context,
                                  LastWishesRoutePaths.preview,
                                  arguments: {'noteId': 'last_wishes'},
                                );
                              }
                            : null,
                        child: Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: notifier.canGoNext
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
        );
      },
    );
  }
}
