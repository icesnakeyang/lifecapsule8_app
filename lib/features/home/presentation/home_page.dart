import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/sync/sync_stage.dart';
import 'package:lifecapsule8_app/features/future_letter/future_letter_route_paths.dart';
import 'package:lifecapsule8_app/features/history/history_route_paths.dart';
import 'package:lifecapsule8_app/features/inspiration/inspiration_route_paths.dart';
import 'package:lifecapsule8_app/features/love_letter/love_route_paths.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/private_note/private_note_route_paths.dart';
import 'package:lifecapsule8_app/features/settings/settings_route_paths.dart';
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_route_paths.dart';

import '../../../app/theme/theme_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _dismissSyncBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider); // ✅ 新版主题（AppTheme）
    final stage = ref.watch(syncStageProvider);
    final needSetupSync = stage < 2;
    final noteCountAsync = ref.watch(notesCountProvider);
    final noteCount = noteCountAsync.value ?? 0;
    final showSyncBanner =
        needSetupSync && noteCount >= 10 && !_dismissSyncBanner;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),

            Align(
              alignment: Alignment.topRight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      SettingsRoutePaths.settings,
                    ),
                    icon: const Icon(Icons.settings, size: 24),
                  ),
                  if (needSetupSync)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (showSyncBanner) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SyncBannerCard(
                  onTap: () =>
                      Navigator.pushNamed(context, SettingsRoutePaths.settings),
                  onClose: () => setState(() => _dismissSyncBanner = true),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 16),

            Text(
              "LifeCapsule",
              style: TextStyle(
                color: theme.primary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFamily: 'Fredoka',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Write a letter to the future",
              style: TextStyle(
                color: theme.onSurface.withOpacity(0.75),
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 32),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 1000
                    ? 5
                    : constraints.maxWidth >= 700
                    ? 4
                    : constraints.maxWidth >= 500
                    ? 3
                    : constraints.maxWidth >= 200
                    ? 2
                    : 1;

                final itemWidth =
                    (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                    crossAxisCount;
                final itemHeight = itemWidth * 3 / 4;

                return Wrap(
                  spacing: 16,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                    _HomeTile(
                      width: itemWidth,
                      height: itemHeight,
                      asset: 'assets/icons/private_note.png',
                      label: 'Private Note',
                      onTap: () => Navigator.pushNamed(
                        context,
                        PrivateNoteRoutePaths.edit,
                      ),
                    ),
                    _HomeTile(
                      width: itemWidth,
                      height: itemHeight,
                      asset: 'assets/icons/love2.png',
                      label: 'Love Letters',
                      onTap: () =>
                          Navigator.pushNamed(context, LoveRoutePaths.edit),
                    ),
                    _HomeTile(
                      width: itemWidth,
                      height: itemHeight,
                      asset: 'assets/icons/wishes.png',
                      label: 'Last Wishes',
                      onTap: () => Navigator.pushNamed(
                        context,
                        LastWishesRoutePaths.intro,
                      ),
                    ),
                    _HomeTile(
                      width: itemWidth,
                      height: itemHeight,
                      asset: 'assets/icons/inspiration.png',
                      label: 'Inspiration',
                      onTap: () => Navigator.pushNamed(
                        context,
                        InspirationRoutePaths.page,
                      ),
                    ),
                    _HomeTile(
                      width: itemWidth,
                      height: itemHeight,
                      asset: 'assets/icons/future.png',
                      label: 'To the Future',
                      onTap: () => Navigator.pushNamed(
                        context,
                        FutureLetterRoutePaths.write,
                      ),
                      labelRadius: 12,
                    ),
                    _HomeTile(
                      width: itemWidth,
                      height: itemHeight,
                      asset: 'assets/icons/history.png',
                      label: 'History',
                      onTap: () => Navigator.pushNamed(
                        context,
                        HistoryRoutePaths.history,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final double width;
  final double height;
  final String asset;
  final String label;
  final VoidCallback onTap;
  final double labelRadius;

  const _HomeTile({
    required this.width,
    required this.height,
    required this.asset,
    required this.label,
    required this.onTap,
    this.labelRadius = 999,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(labelRadius),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncBannerCard extends ConsumerWidget {
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _SyncBannerCard({required this.onTap, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = Stopwatch()..start();
    print('Home build cost: ${sw.elapsedMicroseconds} ms');
    final theme = ref.watch(appThemeProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // ✅ 底色更突出一点（轻柔的蓝/紫系）
            color: theme.warning,

            // ✅ 边框更明显一点
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: Colors.black.withValues(alpha: .06),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keep your LifeCapsule safe',
                            style: TextStyle(
                              color: theme.onWarning,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "You've written a lot already.\n"
                            "Enable secure backup now to keep everything safe.",
                            style: TextStyle(
                              height: 1.25,
                              fontSize: 15,
                              color: Colors.black.withOpacity(0.70),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ 右上角关闭按钮（不触发 onTap）
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  iconSize: 24,
                  splashRadius: 24,
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
