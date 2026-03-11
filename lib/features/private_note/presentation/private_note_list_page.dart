import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/core/utils/date_time_utils.dart';
import 'package:lifecapsule8_app/features/private_note/appication/private_note_list_controller.dart';
import 'package:lifecapsule8_app/features/private_note/private_note_route_paths.dart';

class PrivateNoteListPage extends ConsumerWidget {
  const PrivateNoteListPage({super.key});

  Future<void> _deleteWithUndo(
    BuildContext context,
    WidgetRef ref,
    PrivateNoteListItem item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(privateNoteListControllerProvider.notifier);
    final theme = ref.read(appThemeProvider);
    final palette = theme.privateNote;

    await notifier.deleteById(item.id);
    if (!context.mounted) return;

    messenger.clearSnackBars();

    bool closed = false;

    void closeSnackBarOnce() {
      if (closed) return;
      closed = true;
      messenger.hideCurrentSnackBar();
    }

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: palette.accent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Delete successful',
          style: TextStyle(color: palette.onPrimary),
        ),
        duration: const Duration(seconds: 300),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: palette.onPrimary,
          onPressed: () async {
            await notifier.restore(item.id);
            closeSnackBarOnce();
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 300), closeSnackBarOnce);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PrivateNoteListItem item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete this note?'),
          content: const Text('You can undo right after deleting.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;

    if (ok == true) {
      await _deleteWithUndo(context, ref, item);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(privateNoteListControllerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Private Notes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: () async {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.pushNamed(context, PrivateNoteRoutePaths.edit);
              },
              icon: Icon(Icons.add, size: 24),
            ),
          ],
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
                    subtitle: Text(DateFormatter.ymdHm(item.updatedAt)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isSynced ? Icons.cloud_done : Icons.sync,
                          size: 18,
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(context, ref, item),
                        ),
                      ],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      Navigator.pushNamed(
                        context,
                        PrivateNoteRoutePaths.edit,
                        arguments: {'noteId': item.id},
                      );
                    },
                    onLongPress: () => _confirmDelete(context, ref, item),
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
