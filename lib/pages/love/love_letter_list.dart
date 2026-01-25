import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifecapsule8_app/provider/love_letter/love_letter_draft.dart';
import 'package:lifecapsule8_app/provider/love_letter/love_letter_provider.dart';

class LoveLetterList extends ConsumerStatefulWidget {
  const LoveLetterList({super.key});

  @override
  ConsumerState<LoveLetterList> createState() => _LoveLetterListState();
}

class _LoveLetterListState extends ConsumerState<LoveLetterList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loveLetterProvider);

    // draftsByNoteId 就是你的 HiveBox 内容映射
    final List<LoveLetterDraft> letters = state.draftsByNoteId.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final navigator = Navigator.of(context);
        navigator.popUntil((route) => route.isFirst);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Love Letters",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: () async {
                // ✅ 新建一封：生成新的 noteId，并设为 current
                final id =
                    'love_${DateTime.now().microsecondsSinceEpoch.toString()}';
                await ref
                    .read(loveLetterProvider.notifier)
                    .setCurrentNoteId(id);
                await ref.read(loveLetterProvider.notifier).ensureDraft(id);

                if (!context.mounted) return;
                Navigator.pushNamed(context, '/LoveLetter');
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(158, 135, 2, 111),
                Color.fromARGB(255, 41, 1, 23),
              ],
            ),
          ),
          child: SafeArea(
            child: letters.isEmpty
                ? const Center(
                    child: Text(
                      "No love letters yet",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    itemCount: letters.length,
                    itemBuilder: (context, index) {
                      final item = letters[index];
                      final content = item.content ?? "";
                      final updatedAt = item.updatedAt;
                      final title = content.trim().split("\n").first;

                      return ListTile(
                        title: Text(
                          title.isEmpty ? "(Empty letter)" : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          DateFormat.yMd().add_Hm().format(updatedAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        onTap: () async {
                          // ✅ 设为当前编辑对象，再进编辑页
                          await ref
                              .read(loveLetterProvider.notifier)
                              .setCurrentNoteId(item.noteId);

                          if (!context.mounted) return;
                          Navigator.pushNamed(context, '/LoveLetter');
                        },
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
