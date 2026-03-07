// lib/features/history/ui/history_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/history/application/history_detail_controller.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';

class HistoryDetailPage extends ConsumerWidget {
  final String noteId;
  const HistoryDetailPage({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNote = ref.watch(historyDetailControllerProvider(noteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('History Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(historyDetailControllerProvider(noteId)),
          ),
        ],
      ),
      body: asyncNote.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (note) {
          if (note == null) {
            return const Center(child: Text('Not found'));
          }
          return _Body(note: note);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final NoteBase note;
  const _Body({required this.note});

  @override
  Widget build(BuildContext context) {
    final title = (note.meta['title'] as String?)?.trim();
    final showTitle = title != null && title.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (showTitle)
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (showTitle) const SizedBox(height: 8),
        Text(
          '${note.kind.name} • ${note.updatedAt.toLocal().toIso8601String()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        SelectableText(
          note.content ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      ],
    );
  }
}
