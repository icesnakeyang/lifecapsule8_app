// lib/features/history/ui/history_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/history/application/history_list_controller.dart';
import 'package:lifecapsule8_app/features/history/presentation/history_detail_page.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';

class HistoryListPage extends ConsumerWidget {
  const HistoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(historyListControllerProvider);
    final controller = ref.read(historyListControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: () => controller.refreshRandom(),
          ),
        ],
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('No notes'));

          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = list[i];
              return ListTile(
                title: Text(_title(n)),
                subtitle: Text(
                  _subtitle(n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HistoryDetailPage(noteId: n.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _title(NoteBase n) {
    final t = (n.meta['title'] as String?)?.trim();
    if (t != null && t.isNotEmpty) return t;

    final content = n.content ?? '';
    if (content.isEmpty) return 'Note';
    final firstLine = content.split('\n').first.trim();
    return firstLine.isEmpty ? 'Note' : firstLine;
  }

  String _subtitle(NoteBase n) {
    return '${n.kind.name} • ${n.updatedAt.toLocal().toIso8601String()}';
  }
}
