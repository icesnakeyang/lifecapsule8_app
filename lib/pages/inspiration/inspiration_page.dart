// lib/pages/inspiration/inspiration_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/pages/inspiration/search_highlight_controller.dart';
import 'package:lifecapsule8_app/provider/inspiration/inspiration_provider.dart';
import 'package:lifecapsule8_app/provider/inspiration/inspiration_state.dart';

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

    // 滚动节流保存 scrollTop + cursorOffset（避免频繁写 Hive）
    _scrollCtrl.addListener(() {
      _scrollPersistDebounce?.cancel();
      _scrollPersistDebounce = Timer(const Duration(milliseconds: 300), () {
        final text = _textCtrl.text;
        final sel = _textCtrl.selection;
        final cursor = sel.isValid ? sel.baseOffset : null;

        ref
            .read(inspirationProvider.notifier)
            .updateContent(
              text,
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

  void _applyHydrationIfNeeded(InspirationState s) {
    if (_hydratedOnce) return;
    if (s.loading) return;

    _hydratedOnce = true;

    // 1) 内容
    _textCtrl.text = s.content;

    // 强制初始化为无搜索（保险）
    _searchQ = null;
    _searchCtrl.clear();
    _matchStarts.clear();
    _matchIndex = -1;
    _rebuildMatches(_textCtrl.text, null);
    _syncSearchToController();

    // 3) 光标
    final off = s.cursorOffset;
    if (off != null) {
      final clamped = off.clamp(0, _textCtrl.text.length);
      _textCtrl.selection = TextSelection.collapsed(offset: clamped);
    }

    // 4) 滚动（等一帧确保布局完成）
    final targetScroll = s.scrollTop;
    if (targetScroll != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollCtrl.hasClients) return;
        final max = _scrollCtrl.position.maxScrollExtent;
        final clamped = targetScroll.clamp(0.0, max);
        _scrollCtrl.jumpTo(clamped);
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

    final query = q.trim();
    final lowerText = text.toLowerCase();
    final lowerQ = query.toLowerCase();

    int start = 0;
    while (true) {
      final idx = lowerText.indexOf(lowerQ, start);
      if (idx < 0) break;
      _matchStarts.add(idx);
      start = idx + lowerQ.length;
    }
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

    // ✅ 关键：只移动光标，不做范围选中（避免“选中态”残留）
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

    ref
        .read(inspirationProvider.notifier)
        .updateContent(
          _textCtrl.text,
          cursorOffset: start,
          scrollTop: _scrollCtrl.hasClients ? _scrollCtrl.offset : null,
        );
  }

  void _nextMatch() {
    if (_matchStarts.isEmpty) return;

    if (_matchIndex < 0) {
      _matchIndex = 0;
    } else {
      _matchIndex = (_matchIndex + 1) % _matchStarts.length;
    }

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

    // 恢复光标到当前（避免选中残留）
    final caret = _textCtrl.selection.extentOffset.clamp(
      0,
      _textCtrl.text.length,
    );
    _textCtrl.selection = TextSelection.collapsed(offset: caret);

    _focusNode.requestFocus();
    setState(() {});
  }

  /// ✅ 离开页面前统一清理（避免返回后 hydrate 还带着搜索/选中态）
  void _clearSearchBeforeLeave() {
    // UI state
    _searchQ = null;
    _matchStarts.clear();
    _matchIndex = -1;
    _syncSearchToController();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(inspirationProvider);
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
        await ref.read(inspirationProvider.notifier).persistNow();
        if (context.mounted) Navigator.of(context).pop(result);
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 3, 69, 122),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 3, 69, 122),
          centerTitle: false,
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              _clearSearchBeforeLeave();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text(
            'Inspiration',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Search',
              onPressed: _openSearchDialog,
              icon: const Icon(Icons.search, color: Colors.white),
            ),
            if (hasSearch) ...[
              IconButton(
                tooltip: 'Prev match',
                onPressed: matchCount == 0 ? null : _prevMatch,
                icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
              ),
              IconButton(
                tooltip: 'Next match',
                onPressed: matchCount == 0 ? null : _nextMatch,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    matchCount == 0 ? '0' : '$currentNo/$matchCount',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .75),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Clear search',
                onPressed: _clearSearchOnMain,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
            IconButton(
              tooltip: 'Unfocus',
              onPressed: () => _focusNode.unfocus(),
              icon: const Icon(Icons.keyboard_hide, color: Colors.white),
            ),
            IconButton(
              tooltip: 'Reload',
              onPressed: () => ref.read(inspirationProvider.notifier).load(),
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _focusNode.requestFocus();
          },
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
                      color: Theme.of(context).colorScheme.errorContainer,
                    ),
                    child: Text(
                      s.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
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
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  border: InputBorder.none,
                                  alignLabelWithHint: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: Colors.white,
                                ),
                                cursorColor: Colors.white54,
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
                                      .read(inspirationProvider.notifier)
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
    );
  }

  Future<void> _openSearchDialog() async {
    final s = ref.read(inspirationProvider);
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
              title: const Text('Search'),
              content: TextField(
                controller: _searchCtrl,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Type keyword...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            _searchCtrl.clear();
                            setLocal(() {});

                            // 新增：触发保存
                            final text = _textCtrl.text;
                            final sel = _textCtrl.selection;
                            final cursor = sel.isValid ? sel.baseOffset : null;
                            final scrollTop = _scrollCtrl.hasClients
                                ? _scrollCtrl.offset
                                : null;
                            ref
                                .read(inspirationProvider.notifier)
                                .updateContent(
                                  text,
                                  cursorOffset: cursor,
                                  scrollTop: scrollTop,
                                );

                            _searchQ = null;
                            _rebuildMatches(_textCtrl.text, _searchQ);
                            _syncSearchToController();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (v) {
                  final q = v.trim().isEmpty ? null : v.trim();
                  setLocal(() {});

                  // 新增：触发保存
                  final text = _textCtrl.text;
                  final sel = _textCtrl.selection;
                  final cursor = sel.isValid ? sel.baseOffset : null;
                  final scrollTop = _scrollCtrl.hasClients
                      ? _scrollCtrl.offset
                      : null;
                  ref
                      .read(inspirationProvider.notifier)
                      .updateContent(
                        text,
                        cursorOffset: cursor,
                        scrollTop: scrollTop,
                      );

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
                  child: const Text('Prev'),
                ),
                TextButton(
                  onPressed: _matchStarts.isEmpty ? null : _nextMatch,
                  child: const Text('Next'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
