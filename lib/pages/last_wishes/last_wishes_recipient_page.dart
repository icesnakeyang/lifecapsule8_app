// lib/pages/last_wishes/last_wishes_recipient_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/provider/last_wishes/last_wishes_provider.dart';

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

  final _emailFocus = FocusNode();
  final _email2Focus = FocusNode();

  bool _inited = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _email2Ctrl.dispose();
    _noteCtrl.dispose();
    _emailFocus.dispose();
    _email2Focus.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    final s = ref.read(lastWishesProvider);
    _emailCtrl.text = s.recipientEmail ?? '';
    _email2Ctrl.text = s.recipientEmail ?? '';
    _noteCtrl.text = s.messageNote ?? '';
  }

  bool _isValidEmail(String v) {
    final e = v.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(lastWishesProvider);
    final notifier = ref.read(lastWishesProvider.notifier);

    final email1 = _emailCtrl.text.trim();
    final email2 = _email2Ctrl.text.trim();

    final emailsMatch = email1.isNotEmpty && email1 == email2;
    final emailOk = _isValidEmail(email1) && emailsMatch;

    final years = s.waitingYears;
    final yearsOk = years != null && const [1, 5, 10, 20].contains(years);

    final canContinue = emailOk && yearsOk;

    return Scaffold(
      backgroundColor: const Color(0xFF0E2A1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2A1C),
        leading: BackButton(
          onPressed: () {
            notifier.back();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Recipient & Timing',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const _IntroCard(),
              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _SectionCard(
                        title: 'Recipient email',
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: Colors.white70),
                                hintText: 'name@example.com',
                                hintStyle: TextStyle(color: Colors.white38),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white24),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(14),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFF4BE38A),
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(14),
                                  ),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _email2Ctrl,
                              focusNode: _email2Focus,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Confirm email',
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                hintText: 'Re-enter the same email',
                                hintStyle: const TextStyle(
                                  color: Colors.white38,
                                ),
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white24),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(14),
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFF4BE38A),
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(14),
                                  ),
                                ),
                                helperText: email1.isEmpty
                                    ? 'Double-check. We can’t verify your recipient.'
                                    : (emailsMatch
                                          ? 'Looks good.'
                                          : 'Emails do not match.'),
                                helperStyle: TextStyle(
                                  color: emailsMatch
                                      ? const Color(0xFF4BE38A)
                                      : Colors.white54,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 6),
                            if (email1.isNotEmpty && !emailOk)
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Please enter a valid email twice.',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        title: 'Waiting period',
                        child: _YearsChips(
                          value: years,
                          onSelect: (y) => notifier.setWaitingYears(y),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        title: 'Message note (optional)',
                        subtitle:
                            'A short line to help them understand what this is.',
                        child: TextField(
                          controller: _noteCtrl,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText:
                                'Example: “Please read this when the time comes.”',
                            hintStyle: TextStyle(color: Colors.white38),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                              borderRadius: BorderRadius.all(
                                Radius.circular(14),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF4BE38A)),
                              borderRadius: BorderRadius.all(
                                Radius.circular(14),
                              ),
                            ),
                          ),
                          onChanged: (v) => notifier.setMessageNote(v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        notifier.back();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: canContinue
                          ? () {
                              // 写入 provider
                              notifier.setRecipientEmail(email1);
                              notifier.setMessageNote(_noteCtrl.text);

                              notifier.next();
                              Navigator.pushNamed(
                                context,
                                '/LastWishesPreviewPage',
                              );
                            }
                          : null,
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),

              if (s.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  s.error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF163B28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: const Text(
        'Choose someone you trust.\n'
        'We will wait, and only deliver your words if you can no longer respond.',
        style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 14),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({required this.title, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF163B28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _YearsChips extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onSelect;

  const _YearsChips({required this.value, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const options = [1, 5, 10, 20];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final y in options)
          ChoiceChip(
            selected: value == y,
            label: Text('$y year${y == 1 ? '' : 's'}'),
            labelStyle: TextStyle(
              color: value == y ? const Color(0xFF0E2A1C) : Colors.white70,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: const Color(0xFF4BE38A),
            backgroundColor: const Color(0xFF0E2A1C),
            shape: StadiumBorder(
              side: BorderSide(
                color: value == y ? const Color(0xFF4BE38A) : Colors.white24,
              ),
            ),
            onSelected: (_) => onSelect(y),
          ),
      ],
    );
  }
}
