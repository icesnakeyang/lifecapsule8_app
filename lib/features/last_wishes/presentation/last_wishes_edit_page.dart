import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';

import 'package:lifecapsule8_app/features/last_wishes/application/last_wishes_edit_controller.dart';
// ⚠️ 这里先别用
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_route_paths.dart';

class LastWishesEditPage extends ConsumerStatefulWidget {
  const LastWishesEditPage({super.key});

  @override
  ConsumerState<LastWishesEditPage> createState() => _LastWishesEditPageState();
}

class _LastWishesEditPageState extends ConsumerState<LastWishesEditPage> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  bool _hydrated = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _hydrateIfNeeded(LastWishesEditState s) {
    if (_hydrated) return;
    final n = s.note;
    if (n == null) return;

    _hydrated = true;
    _ctrl.text = n.content ?? '';
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);

    _ctrl.addListener(() {
      ref
          .read(lastWishesEditControllerProvider.notifier)
          .setContent(_ctrl.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(lastWishesEditControllerProvider);
    final theme = ref.read(appThemeProvider);
    final palette = theme.wishes;

    return asyncState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Last Wishes')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (s) {
        _hydrateIfNeeded(s);

        final contentTrimmed = _ctrl.text.trim();
        final canNext = contentTrimmed.isNotEmpty;

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text(
              'Last Wishes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () async {
                _focus.unfocus();
                await ref
                    .read(lastWishesEditControllerProvider.notifier)
                    .saveNow();
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
            centerTitle: false,
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
                child: Column(
                  children: [
                    if (s.error != null && s.error!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          s.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        maxLines: null,
                        minLines: 8,
                        style: TextStyle(
                          color: palette.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Write your last wishes here…',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.accent,
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
                            overlayColor: WidgetStateProperty.all(
                              Colors.white.withValues(alpha: 0.12),
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          onPressed: canNext
                              ? () async {
                                  _focus.unfocus();
                                  await ref
                                      .read(
                                        lastWishesEditControllerProvider
                                            .notifier,
                                      )
                                      .saveNow();
                                  if (!context.mounted) return;

                                  // 下一步：recipient（你后面要我再生成）
                                  Navigator.pushNamed(
                                    context,
                                    LastWishesRoutePaths.recipient,
                                    arguments: {'noteId': 'last_wishes'},
                                  );
                                }
                              : null,
                          child: Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: palette.onPrimary,
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
