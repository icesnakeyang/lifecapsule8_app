import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/appication/future_letter_draft_store.dart';
import 'package:lifecapsule8_app/features/future_letter/appication/future_letter_list_controller.dart';
import 'package:lifecapsule8_app/features/future_letter/future_letter_route_paths.dart';
import 'package:lifecapsule8_app/features/home/home_route_paths.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';

class FutureLetterListPage extends ConsumerStatefulWidget {
  const FutureLetterListPage({super.key});

  @override
  ConsumerState<FutureLetterListPage> createState() =>
      _FutureLetterListPageState();
}

class _FutureLetterListPageState extends ConsumerState<FutureLetterListPage> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncS = ref.watch(futureLetterListControllerProvider);
    final notifier = ref.read(futureLetterListControllerProvider.notifier);
    final theme = ref.read(appThemeProvider);
    final palette = theme.future;

    final s = asyncS;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Future Letters',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: palette.onPrimary,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              HomeRoutePaths.home,
              (route) => false,
            );
          },
          icon: Icon(Icons.arrow_back, color: palette.onPrimary),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () async {
              final newNoteId = ref
                  .read(futureLetterDraftStoreProvider.notifier)
                  .startNewDraft();
              if (!context.mounted) return;
              Navigator.pushNamed(
                context,
                FutureLetterRoutePaths.write,
                arguments: {'noteId': newNoteId},
              );
            },
            icon: const Icon(Icons.add, size: 24),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtl,
              textInputAction: TextInputAction.search,
              onChanged: notifier.setQuery,
              decoration: InputDecoration(
                fillColor: Colors.transparent,
                hintText: 'Search...',
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtl.text.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtl.clear();
                          notifier.setQuery('');
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
        ),
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
          child: _Body(state: s, loading: s.loading),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final FutureLetterListState state;
  final bool loading;

  const _Body({required this.state, required this.loading});

  Future<void> _deleteWithUndo(
    BuildContext context,
    WidgetRef ref,
    NoteBase n,
  ) async {
    final repo = ref.read(notesRepositoryProvider);
    final notifier = ref.read(futureLetterListControllerProvider.notifier);

    final content = (n.content ?? '').trim();
    if (content.isEmpty) {
      await repo.delete(n.id);
      await notifier.refresh();
      return;
    }

    // 先保存一份用于撤销
    final backup = n;

    await repo.markDeleted(n.id);
    await notifier.refresh();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await repo.upsert(
              backup.copyWith(
                isDeleted: false,
                isSynced: false,
                updatedAt: DateTime.now(),
                version: backup.version + 1,
              ),
            );
            await notifier.refresh();
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    NoteBase n,
  ) async {
    final theme = ref.read(appThemeProvider);
    final palette = theme.future;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: palette.accent,
          title: const Text('Delete this letter?'),
          content: const Text('You can undo right after deleting.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: palette.onPrimary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete', style: TextStyle(color: palette.onPrimary)),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await _deleteWithUndo(context, ref, n);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && (state.items.isEmpty)) {
      return _ErrorState(msg: state.error!);
    }

    final items = state.filtered;
    if (items.isEmpty) {
      return const _EmptyState();
    }
    final theme = ref.read(appThemeProvider);
    final palette = theme.future;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final n = items[i];
        final content = (n.content ?? '').toString().trim();
        final displaySubtitle = 'Updated: ${_fmt(n.updatedAt)}';

        return Material(
          color: palette.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pushNamed(
                context,
                FutureLetterRoutePaths.write,
                arguments: {'noteId': n.id},
              );
            },
            onLongPress: () => _confirmDelete(context, ref, n), // ✅ 长按删除
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content.isEmpty ? '(Empty)' : content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displaySubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, ref, n),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 54,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            const Text(
              'No future letters yet.',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap “New” to create your first one.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String msg;
  const _ErrorState({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 10),
            const Text(
              'Load failed',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}
