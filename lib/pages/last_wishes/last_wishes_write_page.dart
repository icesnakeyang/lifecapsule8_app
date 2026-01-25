// lib/pages/last_wishes/last_wishes_write_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/provider/last_wishes/last_wishes_provider.dart';
import 'package:lifecapsule8_app/theme/theme_provider.dart';

class LastWishesWritePage extends ConsumerStatefulWidget {
  const LastWishesWritePage({super.key});

  @override
  ConsumerState<LastWishesWritePage> createState() =>
      _LastWishesWritePageState();
}

class _LastWishesWritePageState extends ConsumerState<LastWishesWritePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _inited = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    final content = ref.read(lastWishesProvider).content;
    _controller.text = content;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );

    _controller.addListener(() {
      final text = _controller.text;
      ref.read(lastWishesProvider.notifier).setContent(text);

      print('[WritePage] changed len=${text.length}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(lastWishesProvider);
    final canContinue = ref
        .watch(lastWishesProvider.notifier)
        .canContinueFromWrite;

    final theme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0E2A1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2A1C),
        leading: BackButton(
          onPressed: () {
            ref.read(lastWishesProvider.notifier).back();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Write',
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
              // editor
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF163B28),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: 12,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.45,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Write your words here…',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // bottom actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _focusNode.unfocus();
                        ref.read(lastWishesProvider.notifier).back();
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
                              _focusNode.unfocus();
                              ref.read(lastWishesProvider.notifier).next();

                              Navigator.pushNamed(
                                context,
                                '/LastWishesDestinationPage',
                              );
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.wishes,
                        foregroundColor: theme.onWishes,
                        disabledBackgroundColor: theme.wishes.withValues(
                          alpha: 0.35,
                        ),
                      ),
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
