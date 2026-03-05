// lib/welcome_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lifecapsule8_app/pages/dashboard/home_page.dart';
import 'package:lifecapsule8_app/provider/user/user_provider.dart';
import 'package:lifecapsule8_app/theme/theme_provider.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  bool _isLoggingIn = false;

  Future<void> _startLogin() async {
    if (_isLoggingIn) return;
    setState(() => _isLoggingIn = true);

    final success = await ref.read(userProvider.notifier).login();

    if (!mounted) return;

    if (success) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } else {
      setState(() => _isLoggingIn = false);
      final err = ref.read(userProvider).error ?? 'Network error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    return PopScope(
      canPop: false, // 禁止返回键
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.surface,
                theme.surface, // 淡紫灰
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 顶部标题
                            SizedBox(height: 80.h),

                            /// --- Logo / Title ---
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(seconds: 2),
                              child: Text(
                                "LifeCapsule",
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  color: theme.primary,
                                  fontSize: 46.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),

                            // if (isFirstLuanch)
                            //   Text(
                            //     "Welcome! Let's begin your LifeCapsule journey.",
                            //     textAlign: TextAlign.center,
                            //     style: TextStyle(
                            //       fontSize: 18.sp,
                            //       color: Color(0x99c7bced),
                            //     ),
                            //   )
                            // else
                            //   Text(
                            //     "Welcome back. ",
                            //     style: TextStyle(
                            //       fontSize: 26.sp,
                            //       // color: const Color.fromARGB(153, 199, 188, 237),
                            //       color: const Color(0x99c7bced),
                            //       fontWeight: FontWeight.w600,
                            //     ),
                            //   ),

                            const SizedBox(height: 24),

                            /// --- 情绪化文案 ---
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(seconds: 3),
                              child: Text(
                                "Keep the moments that matter,\n"
                                "before they quietly fade away.",
                                style: TextStyle(
                                  fontFamily: "Quicksand",
                                  color: Color(0x99B0A2E3),
                                  fontSize: 20.sp,
                                  height: 1.5,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const Spacer(),

                            /// --- 按钮 ---
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoggingIn ? null : _startLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primary,
                                  foregroundColor: theme.onPrimary,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isLoggingIn
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF1F1C2C),
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          Text(
                                            "Starting...",
                                            style: TextStyle(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        "Start my journey",
                                        style: TextStyle(
                                          fontFamily: "Quicksand",
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            SizedBox(height: 40.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
