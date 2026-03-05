import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/crypto/crypto_provider.dart';
import 'package:lifecapsule8_app/provider/future/future_letter_provider.dart';
import 'package:lifecapsule8_app/provider/last_wishes/last_wishes_provider.dart';
import 'package:lifecapsule8_app/provider/sync/sync_coordinator.dart';
import 'package:lifecapsule8_app/provider/user/user_info.dart';
import 'package:lifecapsule8_app/provider/user/user_provider.dart';
import 'package:lifecapsule8_app/theme/theme_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final UserInfo? user = userState.currentUser;
    final theme = ref.watch(themeProvider);
    ref.watch(syncCoordinatorProvider);
    final crypto = ref.watch(cryptoProvider);
    final isEncrypted = crypto.hasMnemonic && crypto.hasMasterKey;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32,),
            Align(
              alignment: Alignment.topRight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    icon: Icon(Icons.settings, size: 24),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "LifeCapsule",
              style: TextStyle(
                color: theme.primary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Write a letter to the future",
              style: TextStyle(
                color: theme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: 'Fredoka',
              ),
            ),
            const SizedBox(height: 32),

            // 修复：使用 LayoutBuilder 适配宽度，避免溢出
            LayoutBuilder(
              builder: (context, constraints) {
                // 根据可用宽度决定每行显示数量：
                // 宽度充足（≥ 500）→ 每行3个；宽度中等（≥ 350）→ 每行2个；否则→每行1个
                final crossAxisCount = constraints.maxWidth >= 600
                    ? 6
                    : constraints.maxWidth >= 1000
                    ? 5
                    : constraints.maxWidth >= 700
                    ? 4
                    : constraints.maxWidth >= 500
                    ? 3
                    : constraints.maxWidth >= 200
                    ? 2
                    : 1;

                // 计算每个标签的宽度（减去间距后平均分配）
                final itemWidth =
                    (constraints.maxWidth -
                        (crossAxisCount - 1) * 16) // 间距：16px/个
                    /
                    crossAxisCount;
                final itemHeight=itemWidth*3/4;

                return Wrap(
                  // 水平间距
                  spacing: 16,
                  // 垂直间距
                  runSpacing: 24,
                  // 居中对齐
                  alignment: WrapAlignment.center,
                  children: 
                  [
                    // 1. Notes
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/noteedit');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: itemWidth,
                        height: itemHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: AssetImage('assets/icons/private_note.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    "Private Note",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Love Letters
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/LoveLetter');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: itemWidth,
                        height: itemHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: AssetImage('assets/icons/love2.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    "Love Letters",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.onLove,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 3. Last Wishes
                    InkWell(
                      onTap: () {
                        final s = ref.read(lastWishesProvider);
                        if (s.enabled) {
                          Navigator.pushNamed(context, '/LastWishesViewPage');
                        } else {
                          Navigator.pushNamed(context, '/LastWishesIntroPage');
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: itemWidth,
                        height: itemHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: AssetImage('assets/icons/wishes.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    "Last Wishes",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 4. Inspiration
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/InspirationPage');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: itemWidth,
                        height: itemHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: AssetImage('assets/icons/inspiration.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    "Inspiration",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 5. To the Future
                    InkWell(
                      onTap: () {
                        ref.read(futureLetterProvider.notifier).startNewDraft();
                        Navigator.pushNamed(context, '/FutureLetterWritePage');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: itemWidth,
                        height: itemHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: AssetImage('assets/icons/future.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "To the Future",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 6. My History
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: itemWidth,
                        height: itemHeight,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: AssetImage('assets/icons/history.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsetsGeometry.only(
                                  bottom: 8,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),

                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(999),
                                  ),

                                  child: Text(
                                    'History',
                                    style: TextStyle(
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
