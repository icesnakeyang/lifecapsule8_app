import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/home/home_route_paths.dart';
import 'package:lifecapsule8_app/features/love_letter/application/love_letter_list_controller.dart';
import 'package:lifecapsule8_app/features/love_letter/love_route_paths.dart';

class LoveLetterListPage extends ConsumerWidget {
  const LoveLetterListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(loveLetterListControllerProvider);
    final theme = ref.read(appThemeProvider);
    final palette = theme.loveLetter;

    return listAsync.when(
      loading: () => Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: palette.onPrimary),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: theme.error, fontSize: 16),
          ),
        ),
      ),
      data: (state) {
        final letters = state.items;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.pushNamed(context, HomeRoutePaths.home);
          },
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                "Love Letters",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.onPrimary,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () async {
                    // 生成新 id（统一用 controller 的方法）
                    final newId = ref
                        .read(loveLetterListControllerProvider.notifier)
                        .createNewNoteId();

                    if (!context.mounted) return;

                    // 直接跳转编辑页，编辑页会处理 draft 创建和 open
                    Navigator.pushNamed(
                      context,
                      LoveRoutePaths.edit,
                      arguments: newId,
                    );
                  },
                  icon: const Icon(Icons.add, size: 28),
                ),
              ],
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
                child: letters.isEmpty
                    ? Center(
                        child: Text(
                          "No love letters yet",
                          style: TextStyle(
                            color: palette.onPrimary,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: letters.length,
                        itemBuilder: (context, index) {
                          final item = letters[index];
                          return Dismissible(
                            key: ValueKey(item.noteId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: theme.error,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: Icon(
                                Icons.delete,
                                color: palette.onPrimary,
                              ),
                            ),
                            onDismissed: (direction) async {
                              // 删除
                              await ref
                                  .read(
                                    loveLetterListControllerProvider.notifier,
                                  )
                                  .deleteLetter(item.noteId);
                            },
                            child: ListTile(
                              title: Text(
                                item.title.isEmpty
                                    ? "(Empty letter)"
                                    : item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: palette.onPrimary,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat.yMd().add_Hm().format(
                                  item.updatedAt,
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Quicksand',
                                  color: palette.onPrimary,
                                ),
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  LoveRoutePaths.edit,
                                  arguments: {'noteId': item.noteId},
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
