import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/crypto/crypto_provider.dart';
import 'package:lifecapsule8_app/provider/app_luanch_provider.dart';
import 'package:lifecapsule8_app/provider/note/note_provider.dart';
import 'package:lifecapsule8_app/theme/theme_provider.dart';

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

  bool _showTip1 = true;
  bool _showPrivateInfo = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initNote();
    });
  }

  Future<void> _initNote() async {
    final notifier = ref.read(noteProvider.notifier);
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

    // 避免重复 listener：先清理再赋值（更稳）
    _controller.removeListener(_onTextChanged);
    _controller.text = current.content;
    _controller.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });

    setState(() {});
  }

  void _onTextChanged() {
    final id = _noteId;
    if (id == null) return;
    ref.read(noteProvider.notifier).updateNoteById(id, _controller.text);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// 切后台自动保存
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_noteId != null) {
        ref
            .read(noteProvider.notifier)
            .autoSaveOnBackground(_noteId!, _controller.text);
      }
    }
  }

  Future<void> _saveOrCreateBeforePop() async {
    final notifier = ref.read(noteProvider.notifier);
    if (_noteId != null) {
      await notifier.saveOrDeleteNoteById(_noteId!, _controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final crypto = ref.watch(cryptoProvider);
    final hasKey = crypto.hasMnemonic && crypto.hasMasterKey;
    final theme = ref.watch(themeProvider);
    final launchCount = ref.watch(appLaunchProvider);
    final isFirstLuanch = launchCount <= 10;

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
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },

                  ///todo 如果失败，成功显示sync
                  icon: Icon(
                    Icons.sync_problem,
                    color: theme.error,
                    // hasKey ? Icons.lock : Icons.lock_open,
                    // color: hasKey ? theme.success : theme.error,
                  ),
                ),
              ],
            ),
          ],
        ),

        body: Container(
          color: theme.surface,
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 顶部「私密空间」提示卡片（可折叠）
              if (_showPrivateInfo && isFirstLuanch) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.surface2.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showPrivateInfo)
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 18,
                              color: theme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This is your private space.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.onSurface,
                                ),
                              ),
                            ),

                            if (_showPrivateInfo)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showPrivateInfo = !_showPrivateInfo;
                                  });
                                },
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Icon(
                                    Icons.cancel,
                                    size: 18,
                                    fontWeight: FontWeight.w700,
                                    color: theme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      if (_showPrivateInfo) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Write whatever is on your mind. '
                          'Your note is stored locally, encrypted on the server, '
                          'and will be synced automatically. No one else can read it.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.onSurface.withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              /// 中部：编辑区 + 小提示
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  readOnly: !canEdit,
                  maxLines: null,

                  keyboardType: TextInputType.multiline,
                  style: TextStyle(
                    color: theme.onSurface.withValues(alpha: 0.9),
                    fontSize: 18,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(4),
                    filled: false,
                    fillColor: Colors.red,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: theme.surface, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.surface),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.surface),
                    ),
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

              if (_showTip1 && isFirstLuanch) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.surface2.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Icon(Icons.info_outline, size: 16, color: theme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can be completely honest here. '
                          'Write down your worries, hopes, thoughts or anything you don’t want to lose.',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.onSurface.withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showTip1 = false;
                          });
                        },
                        child: Icon(
                          Icons.cancel,
                          size: 16,
                          color: theme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
