import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/home/home_route_paths.dart';
import 'package:lifecapsule8_app/features/love_letter/application/love_letter_action_controller.dart';
import 'package:lifecapsule8_app/features/love_letter/love_route_paths.dart';

class LoveLetterActionPage extends ConsumerStatefulWidget {
  final String? noteId;
  const LoveLetterActionPage({super.key, this.noteId});

  @override
  ConsumerState<LoveLetterActionPage> createState() =>
      _LoveLetterActionPageState();
}

class _LoveLetterActionPageState extends ConsumerState<LoveLetterActionPage> {
  @override
  void initState() {
    super.initState();
    // 在页面构建完成后加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.noteId != null) {
        ref
            .read(loveLetterActionControllerProvider.notifier)
            .loadNote(widget.noteId);
      }
    });
  }

  void _goHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      HomeRoutePaths.home,
      (route) => false,
    );
  }

  void _goRecipient(BuildContext context, String noteId) {
    Navigator.pushNamed(
      context,
      LoveRoutePaths.recipient,
      arguments: {'noteId': noteId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    final actionAsync = ref.watch(loveLetterActionControllerProvider);

    return actionAsync.when(
      loading: () => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.loveLetter.gradientStart,
                theme.loveLetter.gradientEnd,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ),

      error: (err, stack) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.loveLetter.gradientStart,
                theme.loveLetter.gradientEnd,
              ],
            ),
          ),
          child: Center(
            child: Text(
              'Error: $err',
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        ),
      ),

      data: (state) {
        final note = state.note;
        final id = note?.id;

        if (note == null || id == null) {
          return Scaffold(
            body: Center(
              child: Text(
                state.error ?? 'No letter available',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: Text(
              'Love Letter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.loveLetter.onPrimary,
                shadows: const [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: theme.loveLetter.onPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.loveLetter.gradientStart,
                  theme.loveLetter.gradientEnd,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What would you like to do with this letter?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.loveLetter.onPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how this letter should live on.',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.loveLetter.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ChoiceCard(
                      title: 'Keep it private',
                      subtitle: 'Only you will ever read this letter',
                      icon: Icons.lock_outline_rounded,
                      color: theme.loveLetter.primary.withOpacity(0.18),
                      accentColor: theme.loveLetter.accent,
                      onTap: () => _goHome(context),
                    ),
                    const SizedBox(height: 16),
                    _ChoiceCard(
                      title: 'Send to someone',
                      subtitle: 'Let it reach them when the time is right',
                      icon: Icons.send_rounded,
                      color: theme.loveLetter.primary.withOpacity(0.22),
                      accentColor: theme.loveLetter.accent,
                      onTap: () => _goRecipient(context, id),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: 200,
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: _LetterPreviewCard(
                        content:
                            note.content ??
                            'Dear...\n\nYour letter is ready. Choose its destiny above.',
                        theme: theme,
                      ),
                    ),
                    const SizedBox(height: 40),
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

// _ChoiceCard 和 _LetterPreviewCard 保持原样
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 原代码不变
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: accentColor.withOpacity(1),
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: accentColor.withOpacity(0.6),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterPreviewCard extends StatelessWidget {
  const _LetterPreviewCard({required this.content, required this.theme});

  final String content;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    // 原代码不变
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.loveLetter.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.loveLetter.accent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          content,
          style: TextStyle(
            color: theme.loveLetter.onPrimary.withOpacity(0.92),
            fontSize: 15.5,
            height: 1.65,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
