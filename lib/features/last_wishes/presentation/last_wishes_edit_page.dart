import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/last_wishes/application/controllers/last_wishes_controller.dart';
import 'package:lifecapsule8_app/features/last_wishes/application/controllers/last_wishes_list_controller.dart';
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_route_paths.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_id.dart';

class LastWishesEditPage extends ConsumerStatefulWidget {
  final String? noteId;

  const LastWishesEditPage({super.key, this.noteId});

  @override
  ConsumerState<LastWishesEditPage> createState() => _LastWishesEditPageState();
}

class _LastWishesEditPageState extends ConsumerState<LastWishesEditPage> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  bool _listenerBound = false;
  String? _hydratedNoteId;
  String? _lastSyncedText;
  String? _generatedNoteId;

  String? _readRouteNoteId() {
    String? noteId = widget.noteId;
    final args = ModalRoute.of(context)?.settings.arguments;
    if ((noteId == null || noteId.trim().isEmpty) && args is Map) {
      final v = args['noteId'];
      if (v is String) {
        noteId = v;
      }
    }

    final resolved = (noteId ?? '').trim();
    return resolved.isEmpty ? null : resolved;
  }

  bool get _isCreateMode => _readRouteNoteId() == null;

  String get _workingNoteId {
    final existingId = _readRouteNoteId();
    if (existingId != null) return existingId;

    _generatedNoteId ??= NoteId.newLastWish();
    return _generatedNoteId!;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _bindListenerIfNeeded() {
    if (_listenerBound) return;
    _listenerBound = true;
    _ctrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _ctrl.text;
    if (_lastSyncedText == text) return;

    _lastSyncedText = text;
    ref
        .read(lastWishesControllerProvider(_workingNoteId).notifier)
        .setContent(text);
  }

  void _hydrateIfNeeded(LastWishesState s) {
    _bindListenerIfNeeded();

    if (_hydratedNoteId == s.noteId && _lastSyncedText == s.content) {
      return;
    }

    _hydratedNoteId = s.noteId;
    _lastSyncedText = s.content;

    final selection = _ctrl.selection;
    final text = s.content;

    _ctrl.value = TextEditingValue(
      text: text,
      selection: selection.isValid
          ? TextSelection(
              baseOffset: selection.baseOffset.clamp(0, text.length),
              extentOffset: selection.extentOffset.clamp(0, text.length),
            )
          : TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _goList() async {
    _focus.unfocus();

    final hasContent = _ctrl.text.trim().isNotEmpty;
    if (hasContent) {
      await ref
          .read(lastWishesControllerProvider(_workingNoteId).notifier)
          .saveNow();
      await ref.read(lastWishesListControllerProvider.notifier).refresh();
    }

    if (!mounted) return;
    Navigator.pushNamed(context, LastWishesRoutePaths.list);
  }

  Future<void> _goNext() async {
    _focus.unfocus();

    await ref
        .read(lastWishesControllerProvider(_workingNoteId).notifier)
        .saveNow();
    if (!mounted) return;

    Navigator.pushNamed(
      context,
      LastWishesRoutePaths.recipient,
      arguments: {'noteId': _workingNoteId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final workingNoteId = _workingNoteId;
    final isCreateMode = _isCreateMode;

    final asyncState = ref.watch(lastWishesControllerProvider(workingNoteId));
    final notifier = ref.read(
      lastWishesControllerProvider(workingNoteId).notifier,
    );
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

        final canNext = s.canGoEditNext;

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              isCreateMode ? 'New Last Wishes' : 'Last Wishes',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () async {
                _focus.unfocus();

                if (_ctrl.text.trim().isNotEmpty) {
                  await notifier.saveNow();
                }

                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: () {
                  // _focus.unfocus();
                  FocusScope.of(context).unfocus();
                },
                icon: Icon(Icons.keyboard_hide_rounded),
              ),
              IconButton(
                onPressed: _goList,
                icon: const Icon(Icons.list, size: 24),
              ),
              TextButton(
                onPressed: canNext ? _goNext : null,
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: canNext
                        ? palette.onPrimary
                        : palette.onPrimary.withValues(alpha: 0.5),
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
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        maxLines: null,
                        minLines: 8,
                        cursorColor: palette.onPrimary,
                        cursorWidth: 1.6,
                        cursorRadius: const Radius.circular(1),
                        style: TextStyle(
                          color: palette.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Write your last wishes here…',
                          hintStyle: TextStyle(
                            color: palette.onPrimary.withValues(alpha: 0.45),
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
