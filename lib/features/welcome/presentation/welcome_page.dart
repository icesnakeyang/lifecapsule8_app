import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/home/home_route_paths.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  bool _loading = false;

  void _goHome(BuildContext context) async {
    if (_loading) return;
    setState(() => _loading = true);
    // 让 loading UI 先真正渲染出来（两帧更稳）
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!context.mounted) return;
        Navigator.of(context).pushReplacementNamed(HomeRoutePaths.home);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      body: Container(
        color: theme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            child: Column(
              children: [
                const Spacer(),

                /// Title
                Text(
                  'LifeCapsule',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    letterSpacing: 2.5,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: theme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Keep the moments that matter,\n'
                  'before they quietly fade away.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    height: 1.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: theme.onSurface.withValues(alpha: .75),
                  ),
                ),
                Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => _goHome(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: theme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    child: _loading
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.onPrimary,
                            ),
                          )
                        : const Center(
                            child: Text(
                              'Start',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Quicksand',
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),

                /// Sub text (very subtle)
                Text(
                  'Offline first • Text only • Encrypted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.onSurface.withValues(alpha: .45),
                    fontSize: 13,
                    letterSpacing: 0.6,
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
