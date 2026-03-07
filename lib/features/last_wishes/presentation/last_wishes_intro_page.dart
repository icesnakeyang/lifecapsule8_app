import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_route_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastWishesIntroPage extends ConsumerStatefulWidget {
  const LastWishesIntroPage({super.key});

  @override
  ConsumerState<LastWishesIntroPage> createState() =>
      _LastWishesIntroPageState();
}

class _LastWishesIntroPageState extends ConsumerState<LastWishesIntroPage> {
  bool _inited = false;

  Future<void> _checkAndShowIntroTip() async {
    final prefs = await SharedPreferences.getInstance();
    const section = 'last_wishes_intro';
    const countKey = '${section}_entry_count';

    int count = prefs.getInt(countKey) ?? 0;
    count++;
    await prefs.setInt(countKey, count);

    // 前 30 次访问都显示提示
    if (count <= 300) {
      if (!mounted) return;
      await _showIntroTipDialog(count);
    }
  }

  Future<void> _showIntroTipDialog(int currentCount) async {
    if (!mounted) return;

    final theme = ref.read(appThemeProvider);

    // 与 wishes 主题色匹配的对话框样式
    final dialogBg = theme.wishes.accent.withOpacity(1); // 温暖橙主色半透
    final accentColor = theme.wishes.onPrimary; // 亮金/黄橙强调色
    final textColor = theme.wishes.onPrimary; // 通常白色，确保可读

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 12,
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
          title: Row(
            children: [
              Icon(Icons.portrait, size: 22, color: accentColor),
              const SizedBox(width: 12),
              Text(
                'Last Wishes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              "Write the words you want to leave behind — love, guidance, gratitude, or closure — for family, friends.\n\n"
              "Choose a future delivery date and recipient(s).\n\n"
              "We’ll email you first for confirmation. You have 30 days to review or change anything.\n"
              "If no response, we’ll send your message as written.\n\n"
              "All content is end-to-end encrypted — only your chosen recipient can ever read it.\n\n"
              "Write honestly. These are your words, forever private until the time comes.",
              style: TextStyle(
                fontSize: 15,
                height: 1.2,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('I Understand'),
            ),
          ],
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _checkAndShowIntroTip();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    final palette = theme.wishes;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.wishes.onPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Last Wishes2',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.wishes.onPrimary,
            shadows: const [
              Shadow(
                color: Colors.black45,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        // 使用 wishes 主题色的介绍卡片
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.wishes.primary.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.wishes.accent.withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.wishes.accent.withOpacity(0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Before you write…',
                                style: TextStyle(
                                  color: theme.wishes.onPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'This is not a note for today.\n'
                                'It is something you leave behind when you can no longer speak for yourself.\n\n'
                                'Take a quiet moment. Think about what truly matters.',
                                style: TextStyle(
                                  color: theme.wishes.onPrimary,
                                  fontSize: 16,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 提示卡片
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.wishes.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.wishes.accent.withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            'Tip: You can edit your words anytime before they are released.',
                            style: TextStyle(
                              color: theme.wishes.onSurfaceDim,
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Continue 按钮 - 使用 wishesAccent 作为背景
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.wishes.accent,
                      foregroundColor: theme.wishes.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      shadowColor: theme.wishes.accent.withOpacity(0.5),
                    ),
                    icon: Icon(Icons.arrow_forward_rounded, size: 20),
                    label: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      // ref
                      //     .read(lastWishesProvider.notifier)
                      //     .goTo(LastWishesStep.write);
                      Navigator.pushNamed(context, LastWishesRoutePaths.edit);
                    },
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
