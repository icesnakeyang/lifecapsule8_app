import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/private_note/appication/private_note_list_controller.dart';

import 'package:lifecapsule8_app/features/private_note/private_note_route_paths.dart';

class PrivateNoteListPage extends ConsumerWidget {
  const PrivateNoteListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(privateNoteListControllerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Private Notes',
            style: TextStyle(fontSize: 18 , fontWeight: FontWeight.w700),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: () => ref
                  .read(privateNoteListControllerProvider.notifier)
                  .refresh(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              Navigator.pushNamed(context, PrivateNoteRoutePaths.edit),
          child: const Icon(Icons.add),
        ),
        body: s.loading
            ? const Center(child: CircularProgressIndicator())
            : s.items.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                itemCount: s.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = s.items[i];
                  return ListTile(
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(item.updatedAt.toIso8601String()),
                    trailing: Icon(
                      item.isSynced ? Icons.cloud_done : Icons.sync,
                      size: 18,
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      PrivateNoteRoutePaths.edit,
                      arguments: {'noteId': item.id},
                    ),
                    onLongPress: () async {
                      await ref
                          .read(privateNoteListControllerProvider.notifier)
                          .deleteById(item.id);
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.note_outlined, size: 56),
            SizedBox(height: 12),
            Text('No private notes yet'),
            SizedBox(height: 6),
            Text('Tap + to write your first note'),
          ],
        ),
      ),
    );
  }
}
