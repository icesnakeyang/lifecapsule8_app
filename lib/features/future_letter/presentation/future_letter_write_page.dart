import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/application/future_letter_draft_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/application/future_letter_list_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/future_letter_route_paths.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_id.dart';

class FutureLetterWritePage extends ConsumerStatefulWidget {
  final String? noteId;

  const FutureLetterWritePage({super.key, this.noteId});

  @override
  ConsumerState<FutureLetterWritePage> createState() =>
      _FutureLetterWritePageState();
}

class _FutureLetterWritePageState extends ConsumerState<FutureLetterWritePage> {
  late final String noteId;

  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  bool _isHydrating = false;
  String? _lastHydratedContent;

  @override
  void initState() {
    super.initState();
    noteId = widget.noteId ?? NoteId.newFutureLetter();

    _textCtrl.addListener(() {
      if (_isHydrating) return;

      ref
          .read(futureLetterDraftControllerProvider(noteId).notifier)
          .setContent(_textCtrl.text);

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _persistOnExitOrNext() async {
    final controller = ref.read(
      futureLetterDraftControllerProvider(noteId).notifier,
    );
    controller.setContent(_textCtrl.text);
    await controller.persist();
  }

  void _syncTextIfNeeded(String content) {
    if (_textCtrl.text == content && _lastHydratedContent == content) return;

    _isHydrating = true;
    final selection = _textCtrl.selection;

    _textCtrl.value = TextEditingValue(
      text: content,
      selection: selection.isValid
          ? selection.copyWith(
              baseOffset: selection.baseOffset.clamp(0, content.length),
              extentOffset: selection.extentOffset.clamp(0, content.length),
            )
          : TextSelection.collapsed(offset: content.length),
    );

    _lastHydratedContent = content;
    _isHydrating = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(futureLetterDraftControllerProvider(noteId));
    final theme = ref.watch(appThemeProvider);

    if (!state.loading) {
      _syncTextIfNeeded(state.draft.content);
    }

    final canNext =
        _textCtrl.text.trim().isNotEmpty && !state.loading && !state.saving;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _persistOnExitOrNext();
        if (!context.mounted) return;
        Navigator.of(context).pop(result);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'To Future',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.future.onPrimary,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.future.onPrimary),
            onPressed: () async {
              await _persistOnExitOrNext();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Unfocus',
              onPressed: () => _focusNode.unfocus(),
              icon: Icon(
                Icons.keyboard_hide,
                color: theme.future.accent,
                size: 24,
              ),
            ),
            IconButton(
              tooltip: 'All letters',
              icon: Icon(Icons.list, size: 24, color: theme.future.onPrimary),
              onPressed: () async {
                await _persistOnExitOrNext();
                await ref
                    .read(futureLetterListControllerProvider.notifier)
                    .refresh();
                if (!context.mounted) return;
                Navigator.pushNamed(context, FutureLetterRoutePaths.list);
              },
            ),
            TextButton(
              onPressed: canNext
                  ? () async {
                      await _persistOnExitOrNext();
                      if (!context.mounted) return;
                      Navigator.pushNamed(
                        context,
                        FutureLetterRoutePaths.schedule,
                        arguments: {'noteId': noteId},
                      );
                    }
                  : null,
              child: state.saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.future.onPrimary,
                      ),
                    )
                  : Text(
                      'Next',
                      style: TextStyle(
                        color: canNext
                            ? theme.future.onPrimary
                            : theme.future.onPrimary.withValues(alpha: 0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
        body: state.loading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.future.gradientStart,
                      theme.future.gradientEnd,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      if (state.error != null && state.error!.trim().isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.error.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            state.error!,
                            style: TextStyle(color: theme.onError),
                          ),
                        ),
                      Expanded(
                        child: TextField(
                          controller: _textCtrl,
                          focusNode: _focusNode,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.55,
                            color: theme.future.onPrimary,
                          ),
                          cursorColor: theme.future.accent.withValues(
                            alpha: 0.8,
                          ),
                          decoration: InputDecoration(
                            fillColor: Colors.transparent,
                            hintText: 'Write your letter…',
                            hintStyle: TextStyle(
                              color: theme.future.onPrimary.withValues(
                                alpha: 0.45,
                              ),
                              fontStyle: FontStyle.italic,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
