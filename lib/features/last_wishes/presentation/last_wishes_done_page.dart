import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/home/home_route_paths.dart';
import 'package:lifecapsule8_app/features/last_wishes/application/last_wishes_done_controller.dart';
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_route_paths.dart';

class LastWishesDonePage extends ConsumerStatefulWidget {
  final String? noteId;

  const LastWishesDonePage({super.key, this.noteId});

  @override
  ConsumerState<LastWishesDonePage> createState() => _LastWishesDonePageState();
}

class _LastWishesDonePageState extends ConsumerState<LastWishesDonePage> {
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(lastWishesDoneControllerProvider.notifier);

      String? noteId = widget.noteId;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (noteId == null && args is Map) {
        noteId = args['noteId'] as String?;
      }

      await notifier.setNoteId(noteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(lastWishesDoneControllerProvider);
    final theme = ref.read(appThemeProvider);
    final palette = theme.wishes;
    final on = palette.onPrimary;

    return asyncState.when(
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.gradientStart, palette.gradientEnd],
            ),
          ),
          child: SafeArea(
            child: Center(child: CircularProgressIndicator(color: on)),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Last Wishes',
            style: TextStyle(
              color: on,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          iconTheme: IconThemeData(color: on),
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
            child: Center(
              child: Text(
                'Error: $e',
                style: TextStyle(color: on.withValues(alpha: 0.8)),
              ),
            ),
          ),
        ),
      ),
      data: (s) {
        final ok = s.enabled;
        final iconBg = ok
            ? palette.accent.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.08);

        final cardBg = Colors.white.withValues(alpha: 0.08);
        final cardBorder = on.withValues(alpha: 0.16);

        final title = ok ? 'Last Wishes Enabled' : 'Not Enabled';
        final desc = ok
            ? 'Your message is safely stored.\nWe will follow your delivery settings when the time comes.'
            : 'This draft is not enabled yet.';

        final primaryBtnEnabled = true;

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              'Last Wishes',
              style: TextStyle(
                color: on,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            iconTheme: IconThemeData(color: on),
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                HomeRoutePaths.home,
                (route) => false,
              ),
            ),
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  children: [
                    const Spacer(),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: cardBg,
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: iconBg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ok
                                    ? palette.accent.withValues(alpha: 0.35)
                                    : on.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Icon(
                              ok
                                  ? Icons.verified_rounded
                                  : Icons.info_outline_rounded,
                              size: 46,
                              color: ok
                                  ? palette.accent
                                  : on.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: on.withValues(alpha: 0.95),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            desc,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: on.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: primaryBtnEnabled
                              ? palette.accent
                              : palette.accent.withValues(alpha: 0.35),
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
                            overlayColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (!primaryBtnEnabled) return Colors.transparent;
                              return on.withValues(alpha: 0.12);
                            }),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              LastWishesRoutePaths.list,
                              (route) => false,
                            );
                          },
                          child: Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: on,
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
