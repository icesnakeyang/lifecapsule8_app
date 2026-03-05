import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/constants/onboarding_keys.dart';
import 'package:lifecapsule8_app/crypto/crypto_provider.dart';
import 'package:lifecapsule8_app/provider/note/note_provider.dart';
import 'package:lifecapsule8_app/provider/note/note_state.dart';
import 'package:lifecapsule8_app/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteEdit extends ConsumerStatefulWidget {
  const NoteEdit({super.key});

  @override
  ConsumerState<NoteEdit> createState() => _NoteEditState();
}

class _NoteEditState extends ConsumerState<NoteEdit>
    with WidgetsBindingObserver {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _inited = false;

  String? _noteId;
  String _initialText = '';

  // 标记：是否已完成弹窗关闭，用于控制输入框焦点
  bool _isDialogClosed = false;
  static const _tipDialogShownKey = 'private_note_tip_dialog_shown';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.canRequestFocus = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async{
      if (!mounted) return;
      final prefs=await SharedPreferences.getInstance();
      final section=OnboardingKeys.privateNote;
      final countKey=OnboardingKeys.entryCountKey(section);
      int entryCount=prefs.getInt(countKey)??0;
      entryCount++;
      await prefs.setInt(countKey, entryCount);
      final hasShown=prefs.getBool(OnboardingKeys.tipShownKey(section))??false;
      if(entryCount<=30 && !hasShown){
        await _showCombinedTipDialog(prefs);
      }else{
        _requestInputFocus();
      }
      await _initNote();
    });
  }

  Future<void> _initNote() async {
    final notifier = ref.read(noteProvider.notifier);
    final args = ModalRoute.of(context)?.settings.arguments;
    String? argId;
    bool isNew = false;
    if (args is Map) {
      argId = args['id'] as String?;
      isNew = args['isNew'] as bool? ?? false;
    }
    if (isNew) {
      await notifier.clearCurrentNote();
      final local = await notifier.createEmptyCurrentNote();
      if (!mounted) return;
      _noteId = local.id;
      _controller.text = '';
      _initialText = '';
      setState(() {});
      return;
    }
    if (argId != null && argId.isNotEmpty) {
      _noteId = argId;
      notifier.setCurrentNoteById(argId);
    }

    var current = ref.read(noteProvider).currentNote;
    if (current != null && current.type != 'PRIVATE_NOTE') {
      notifier.clearCurrentNote();
      current = null;
    }
    if (current == null) {
      await notifier.saveCurrentNoteAsNewFromText('');
      current = ref.read(noteProvider).currentNote;
    }

    if (!mounted || current == null) return;

    _noteId = current.id;
    current = ref.read(noteProvider).currentNote;
    if (current == null) return;

    _controller.text = current.content;
    _initialText = _controller.text.trim();

    setState(() {});
  }

  /// 显示合并后的提示弹窗
  Future<void> _showCombinedTipDialog(SharedPreferences prefs) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true, // 点击空白处可关闭
      builder: (ctx) {
        final theme = ref.watch(themeProvider);
        return AlertDialog(
          backgroundColor: theme.surface2.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          title: Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: theme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Private Space',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            'This is your private space. '
            'Write whatever is on your mind. \n\n'
            'Your note is stored locally, encrypted on the server, '
            'and will be synced automatically. No one else can read it.\n\n'
            'You can be completely honest here. Write down your worries, hopes, thoughts or anything you don’t want to lose.',
            style: TextStyle(
              fontSize: 16,
              color: theme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // 弹窗关闭后标记状态，并请求输入框焦点
                _onDialogClosed();
              },
              child: Text(
                'Got it',
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      // 处理点击空白处关闭弹窗的情况
      if (!_isDialogClosed) {
        _onDialogClosed();
      }
    });
  }

  /// 弹窗关闭后的处理逻辑
  void _onDialogClosed() {
    if (!mounted) return;

    setState(() {
      _isDialogClosed = true;
      // 恢复输入框请求焦点的能力
      _focusNode.canRequestFocus = true;
    });

    // 延迟请求焦点，确保弹窗完全关闭后再弹出键盘
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInputFocus();
    });
  }

  /// 统一的焦点请求方法
  void _requestInputFocus() {
    if (!mounted || !_focusNode.canRequestFocus) return;

    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;

    final id = _noteId;
    if (id == null) return;

    final nowText = _controller.text.trim();
    if (_initialText == nowText) return;

    ref
        .read(noteProvider.notifier)
        .autoSaveOnBackground(_noteId!, _controller.text);
  }

  Future<void> _saveOrCreateBeforePop() async {
    final id = _noteId;
    if (id == null) return;
    final currentNote = ref.read(noteProvider).currentNote;
    if (currentNote != null) {
      final a = (currentNote.content).trim();
      final b = (_controller.text).trim();
      if (a == b && currentNote.isSynced == true) {
        return;
      }
    }
    await ref
        .read(noteProvider.notifier)
        .saveOrDeleteNoteById(id, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final crypto = ref.watch(cryptoProvider);
    final theme = ref.watch(themeProvider);
    final hasKey = crypto.hasMnemonic && crypto.hasMasterKey;

    ref.listen<NoteState>(noteProvider, (prev, next) {
      final n = next.currentNote;
      if (n == null) return;
      if (n.isSynced) {
        final t = n.content.trim();
        if (_initialText != t) _initialText = t;
      }
    });

    final isStorageEncrypted =
        _noteId != null &&
        ref.read(noteProvider.notifier).isNoteEncrypted(_noteId!);

    final canEdit = !(isStorageEncrypted && !hasKey);

    final currentNote = ref.watch(noteProvider).currentNote;

    if (currentNote == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initNote();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        await _saveOrCreateBeforePop();
        if (!navigator.mounted) return;
        navigator.pop(result);
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text(
            'Private note',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _saveOrCreateBeforePop();
                if (!navigator.mounted) return;
                navigator.pushNamed('/notelist');
              },
              icon: const Icon(Icons.list),
            ),
            if (_noteId != null)
              IconButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final confirmed =
                      await showDialog<bool>(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: const Text('Delete note'),
                            content: const Text(
                              'Are you sure you want to delete this note?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      ) ??
                      false;
                  if (!mounted || !confirmed) return;

                  await ref
                      .read(noteProvider.notifier)
                      .deleteNoteById(_noteId!);
                  if (!navigator.mounted) return;
                  navigator.pop();
                },
                icon: const Icon(Icons.delete),
              ),
          ],
        ),

        // 输入区域占满整个页面，无任何提示卡片遮挡
        body: Container(
          color: theme.surface,
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (v) {
              final id = _noteId;
              if (id == null) return;
              ref.read(noteProvider.notifier).updateNoteById(id, v);
            },
            readOnly: !canEdit,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            // 关键：初始时不自动弹出键盘
            autofocus: false,
            style: TextStyle(
              color: theme.onSurface.withValues(alpha: 0.9),
              fontSize: 18,
              height: 1.5,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: false,
              fillColor: theme.surface2.withValues(alpha: 0.1),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'Write your mind here safely.',
              hintMaxLines: 3,
              hintStyle: TextStyle(
                color: theme.onDescription.withValues(alpha: 0.45),
                fontSize: 18,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}