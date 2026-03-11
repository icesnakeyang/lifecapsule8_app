// lib/features/inspiration/presentation/inspiration_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';

import 'package:lifecapsule8_app/features/inspiration/application/inspiration_edit_controller.dart';
import 'package:lifecapsule8_app/features/inspiration/application/inspiration_highlight_controller.dart';

class InspirationPage extends ConsumerStatefulWidget {
  const InspirationPage({super.key});

  @override
  ConsumerState<InspirationPage> createState() => _InspirationPageState();
}

class _InspirationPageState extends ConsumerState<InspirationPage> {
  late final SearchHighlightController _textCtrl;
  final _searchCtrl = TextEditingController();

  final _focusNode = FocusNode();
  final _scrollCtrl = ScrollController();

  bool _hydratedOnce = false;
  Timer? _scrollPersistDebounce;

  String? _searchQ;
  final List<int> _matchStarts = [];
  int _matchIndex = -1;

  @override
  void initState() {
    super.initState();

    _textCtrl = SearchHighlightController(
      hintText: 'This is your draft board. Write freely. This space is yours.',
      hintStyle: TextStyle(
        fontSize: 16,
        height: 1.6,
        color: Colors.white.withValues(alpha: .4),
        fontStyle: FontStyle.italic,
      ),
    );

    _scrollCtrl.addListener(() {
      _scrollPersistDebounce?.cancel();
      _scrollPersistDebounce = Timer(const Duration(milliseconds: 300), () {
        final sel = _textCtrl.selection;
        final cursor = sel.isValid ? sel.baseOffset : null;

        ref
            .read(inspirationEditControllerProvider.notifier)
            .updateUiState(
              cursorOffset: cursor,
              scrollTop: _scrollCtrl.hasClients ? _scrollCtrl.offset : null,
            );
      });
    });
  }

  @override
  void dispose() {
    _scrollPersistDebounce?.cancel();
    _textCtrl.dispose();
    _searchCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _applyHydrationIfNeeded(InspirationEditState s) {
    if (_hydratedOnce) return;
    if (s.loading) return;
    final note = s.note;
    if (note == null) return;

    _hydratedOnce = true;

    // 1) 内容
    _textCtrl.text = note.content ?? '';

    // 2) 清搜索
    _searchQ = null;
    _searchCtrl.clear();
    _matchStarts.clear();
    _matchIndex = -1;
    _rebuildMatches(_textCtrl.text, null);
    _syncSearchToController();

    // 3) 光标
    final meta = note.meta;
    final off = meta['cursorOffset'];
    if (off is int) {
      final clamped = off.clamp(0, _textCtrl.text.length);
      _textCtrl.selection = TextSelection.collapsed(offset: clamped);
    }

    // 4) 滚动
    final st = meta['scrollTop'];
    if (st is num) {
      final targetScroll = st.toDouble();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollCtrl.hasClients) return;
        final max = _scrollCtrl.position.maxScrollExtent;
        _scrollCtrl.jumpTo(targetScroll.clamp(0.0, max));
      });
    }

    // 5) 初始化高亮
    _rebuildMatches(_textCtrl.text, _searchQ);
    _syncSearchToController();
  }

  void _rebuildMatches(String text, String? q) {
    _matchStarts.clear();
    _matchIndex = -1;

    if (q == null || q.trim().isEmpty) return;

    final query = q.trim().toLowerCase();
    final lowerText = text.toLowerCase();

    int start = 0;
    while (true) {
      final idx = lowerText.indexOf(query, start);
      if (idx < 0) break;
      _matchStarts.add(idx);
      start = idx + query.length;
    }

    if (_matchStarts.isNotEmpty) _matchIndex = 0;
  }

  void _syncSearchToController() {
    _textCtrl.searchQuery = _searchQ;
    _textCtrl.matchStarts = List.of(_matchStarts);
    _textCtrl.currentMatchIndex = _matchIndex;
    _textCtrl.notifyListeners();
  }

  void _jumpToMatch(int i) {
    if (_matchStarts.isEmpty) return;

    final start = _matchStarts[i].clamp(0, _textCtrl.text.length);
    _textCtrl.selection = TextSelection.collapsed(offset: start);

    _matchIndex = i;
    _syncSearchToController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final lineHeight = 16 * 1.6;
      final before = _textCtrl.text.substring(0, start);
      final lines = '\n'.allMatches(before).length;
      final target = (lines * lineHeight).toDouble();
      _scrollCtrl.animateTo(
        target.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });

    final sel = _textCtrl.selection;
    final cursor = sel.isValid ? sel.baseOffset : null;
    ref
        .read(inspirationEditControllerProvider.notifier)
        .updateUiState(
          cursorOffset: cursor,
          scrollTop: _scrollCtrl.hasClients ? _scrollCtrl.offset : null,
        );
  }

  void _nextMatch() {
    if (_matchStarts.isEmpty) return;
    _matchIndex = _matchIndex < 0 ? 0 : (_matchIndex + 1) % _matchStarts.length;
    _syncSearchToController();
    _jumpToMatch(_matchIndex);
    setState(() {});
  }

  void _prevMatch() {
    if (_matchStarts.isEmpty) return;
    if (_matchIndex < 0) {
      _matchIndex = _matchStarts.length - 1;
    } else {
      _matchIndex = (_matchIndex - 1) < 0
          ? _matchStarts.length - 1
          : _matchIndex - 1;
    }
    _syncSearchToController();
    _jumpToMatch(_matchIndex);
    setState(() {});
  }

  void _clearSearchOnMain() {
    _searchCtrl.clear();
    _searchQ = null;
    _matchStarts.clear();
    _matchIndex = -1;
    _rebuildMatches(_textCtrl.text, _searchQ);
    _syncSearchToController();

    final caret = _textCtrl.selection.extentOffset.clamp(
      0,
      _textCtrl.text.length,
    );
    _textCtrl.selection = TextSelection.collapsed(offset: caret);

    _focusNode.requestFocus();
    setState(() {});
  }

  void _clearSearchBeforeLeave() {
    _searchQ = null;
    _matchStarts.clear();
    _matchIndex = -1;
    _syncSearchToController();
  }

  @override
  Widget build(BuildContext context) {
    final asyncS = ref.watch(inspirationEditControllerProvider);
    final theme = ref.watch(appThemeProvider);
    final palette = theme.inspiration;

    final s = asyncS.value ?? const InspirationEditState(loading: true);
    _applyHydrationIfNeeded(s);

    final hasSearch = (_searchQ ?? '').isNotEmpty;
    final matchCount = _matchStarts.length;
    final currentNo = (matchCount == 0 || _matchIndex < 0)
        ? 0
        : (_matchIndex + 1);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _clearSearchBeforeLeave();
        await ref.read(inspirationEditControllerProvider.notifier).persistNow();
        if (context.mounted) Navigator.of(context).pop(result);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back, color: palette.onPrimary),
            onPressed: () async {
              _clearSearchBeforeLeave();
              await ref
                  .read(inspirationEditControllerProvider.notifier)
                  .persistNow();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          title: Text(
            'Inspiration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: palette.onPrimary,
            ),
          ),
          centerTitle: false,
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Search',
                  onPressed: _openSearchDialog,
                  style: IconButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    Icons.search,
                    color: theme.inspiration.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                if (hasSearch) ...[
                  IconButton(
                    tooltip: 'Prev match',
                    onPressed: matchCount == 0 ? null : _prevMatch,
                    style: IconButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_up,
                      color: theme.inspiration.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Next match',
                    onPressed: matchCount == 0 ? null : _nextMatch,
                    style: IconButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.inspiration.onPrimary,
                      size: 20,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      matchCount == 0 ? '0' : '$currentNo/$matchCount',
                      style: TextStyle(
                        color: theme.inspiration.onPrimary.withOpacity(0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: _clearSearchOnMain,
                    style: IconButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      Icons.close,
                      color: theme.inspiration.onPrimary,
                      size: 20,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Unfocus',
                  onPressed: () => _focusNode.unfocus(),
                  style: IconButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    Icons.keyboard_hide,
                    color: theme.inspiration.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Reload',
                  onPressed: () => ref
                      .read(inspirationEditControllerProvider.notifier)
                      .build(),
                  style: IconButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    Icons.refresh,
                    color: theme.inspiration.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
              ],
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
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _focusNode.requestFocus(),
            child: SafeArea(
              child: Column(
                children: [
                  if (s.error != null && s.error!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.error.withValues(alpha: 0.8),
                      ),
                      child: Text(
                        s.error!,
                        style: TextStyle(color: theme.onError),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                      child: s.loading && !_hydratedOnce
                          ? const Center(child: CircularProgressIndicator())
                          : Scrollbar(
                              controller: _scrollCtrl,
                              child: SingleChildScrollView(
                                controller: _scrollCtrl,
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextField(
                                  controller: _textCtrl,
                                  focusNode: _focusNode,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    fillColor: Colors.transparent,
                                    filled: false,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    alignLabelWithHint: true,
                                  ),
                                  style: TextStyle(
                                    fontSize: 18,
                                    height: 1.6,
                                    color: theme.inspiration.onPrimary,
                                  ),
                                  cursorColor: theme.inspiration.accent
                                      .withValues(alpha: 0.7),
                                  cursorWidth: 1.6,
                                  cursorRadius: const Radius.circular(1),
                                  onChanged: (text) {
                                    _rebuildMatches(text, _searchQ);
                                    _syncSearchToController();

                                    final sel = _textCtrl.selection;
                                    final cursor = sel.isValid
                                        ? sel.baseOffset
                                        : null;

                                    ref
                                        .read(
                                          inspirationEditControllerProvider
                                              .notifier,
                                        )
                                        .updateContent(
                                          text,
                                          cursorOffset: cursor,
                                          scrollTop: _scrollCtrl.hasClients
                                              ? _scrollCtrl.offset
                                              : null,
                                        );
                                  },
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
      ),
    );
  }

  Future<void> _openSearchDialog() async {
    final theme = ref.read(appThemeProvider);
    final palette = theme.inspiration;
    _searchCtrl.text = _searchQ ?? '';
    _searchCtrl.selection = TextSelection.collapsed(
      offset: _searchCtrl.text.length,
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: palette.accent.withValues(alpha: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 40,
              ),
              title: Text(
                'Search',
                style: TextStyle(
                  fontSize: 16,
                  color: palette.onPrimary.withValues(alpha: 1),
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: TextField(
                controller: _searchCtrl,
                autofocus: true,
                textInputAction: TextInputAction.search,
                cursorColor: palette.onPrimary,
                cursorWidth: 2.2,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  color: palette.onPrimary.withValues(alpha: 1),
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  isDense: false,
                  filled: true,
                  fillColor: Colors.transparent,
                  hintText: 'Type keyword...',
                  hintStyle: TextStyle(
                    color: palette.onPrimary.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: palette.onPrimary.withValues(alpha: 0.85),
                  ),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            _searchCtrl.clear();
                            setLocal(() {});
                            _searchQ = null;
                            _rebuildMatches(_textCtrl.text, _searchQ);
                            _syncSearchToController();
                            setState(() {});
                          },
                          icon: Icon(
                            Icons.clear,
                            color: palette.onPrimary.withValues(alpha: 0.75),
                          ),
                        ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.inspiration.accent.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: palette.accent.withValues(alpha: 0.75),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: palette.accent, width: 2.8),
                  ),
                ),
                onChanged: (v) {
                  final q = v.trim().isEmpty ? null : v.trim();
                  setLocal(() {});
                  _searchQ = q;
                  _rebuildMatches(_textCtrl.text, _searchQ);
                  _syncSearchToController();
                  setState(() {});
                },
                onSubmitted: (_) {
                  Navigator.of(ctx).pop();
                  _focusNode.requestFocus();
                },
              ),
              actions: [
                TextButton(
                  onPressed: _matchStarts.isEmpty ? null : _prevMatch,
                  child: Text(
                    'Prev',
                    style: TextStyle(
                      color: palette.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _matchStarts.isEmpty ? null : _nextMatch,
                  child: Text(
                    'Next',
                    style: TextStyle(
                      color: palette.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: palette.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
