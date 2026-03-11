import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/core/utils/date_time_utils.dart';
import 'package:lifecapsule8_app/features/last_wishes/application/controllers/last_wishes_list_controller.dart';
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_route_paths.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_id.dart';

class LastWishesListPage extends ConsumerWidget {
  const LastWishesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lastWishesListControllerProvider);
    final items = state.filtered;

    final theme = ref.read(appThemeProvider);
    final palette = theme.wishes;
    final on = palette.onPrimary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Last Wishes',
          style: TextStyle(
            color: on,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: on),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(lastWishesListControllerProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              Navigator.pushNamed(
                context,
                LastWishesRoutePaths.edit,
                arguments: {'noteId': NoteId.newLastWish()},
              );
            },
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
          child: Builder(
            builder: (context) {
              if (state.loading) {
                return Center(child: CircularProgressIndicator(color: on));
              }

              if (state.error != null && state.error!.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: ${state.error!}',
                      style: TextStyle(color: on.withValues(alpha: 0.85)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (items.isEmpty) {
                return _EmptyView(onPrimary: on);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final n = items[index];
                  return _WishCard(note: n);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WishCard extends ConsumerWidget {
  final NoteBase note;

  const _WishCard({required this.note});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final theme = ref.read(appThemeProvider);
    final palette = theme.wishes;
    final on = palette.onPrimary;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: palette.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete this wish?',
            style: TextStyle(
              color: palette.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'This will remove it from the list.',
            style: TextStyle(color: on.withValues(alpha: 1)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: on.withValues(alpha: 0.8)),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.error.withValues(alpha: 0.95),
                foregroundColor: on,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    await ref.read(lastWishesListControllerProvider.notifier).delete(note.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted successful.',
          style: TextStyle(color: palette.onPrimary),
        ),
        backgroundColor: palette.accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(appThemeProvider);
    final palette = theme.wishes;

    final content = (note.content ?? '').trim();
    final preview = content.isEmpty ? '(Empty)' : content;
    final enabled = (note.meta['enabled'] as bool?) ?? false;
    final years = (note.meta['waitingYears'] as num?)?.toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            LastWishesRoutePaths.edit,
            arguments: {'noteId': note.id},
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: palette.onPrimary.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.onPrimary,
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: palette.onPrimary.withValues(alpha: 0.75),
                    ),
                    tooltip: 'Delete',
                    onPressed: () async {
                      await _confirmDelete(context, ref);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      DateFormatter.ymdHm(note.updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.onPrimary.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (enabled)
                          _Tag(
                            text: 'Enabled',
                            textColor: palette.onPrimary,
                            borderColor: palette.onPrimary.withValues(
                              alpha: 0.16,
                            ),
                            backgroundColor: palette.accent,
                          ),
                        if (years != null)
                          _Tag(
                            text: '$years year${years == 1 ? '' : 's'}',
                            textColor: palette.onPrimary.withValues(alpha: 0.9),
                            borderColor: palette.onPrimary.withValues(
                              alpha: 0.16,
                            ),
                            backgroundColor: palette.accent,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;

  const _Tag({
    required this.text,
    required this.textColor,
    required this.borderColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final Color onPrimary;

  const _EmptyView({required this.onPrimary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No wishes yet',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onPrimary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
