import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifecapsule8_app/app/theme/app_theme.dart';
import 'package:lifecapsule8_app/app/theme/theme_controller.dart';
import 'package:lifecapsule8_app/features/last_wishes/application/last_wishes_list_controller.dart';
import 'package:lifecapsule8_app/features/last_wishes/last_wishes_route_paths.dart';

class LastWishesListPage extends ConsumerWidget {
  const LastWishesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(lastWishesListControllerProvider);
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
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: IconThemeData(color: on),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(lastWishesListControllerProvider.notifier).refresh();
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
          child: asyncState.when(
            loading: () => Center(child: CircularProgressIndicator(color: on)),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: TextStyle(color: on.withValues(alpha: 0.8)),
              ),
            ),
            data: (s) {
              final items = s.items;

              if (items.isEmpty) {
                return _EmptyState(theme: theme);
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return _WishCard(
                    theme: theme,
                    title: item.title ?? 'Untitled',
                    preview: item.preview ?? '',
                    enabled: item.enabled,
                    waitingYears: item.waitingYears,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        LastWishesRoutePaths.preview,
                        arguments: {'noteId': item.id},
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: palette.accent,
        onPressed: () {
          Navigator.pushNamed(
            context,
            LastWishesRoutePaths.edit,
            arguments: {'noteId': null},
          );
        },
        child: Icon(Icons.add_rounded, color: on),
      ),
    );
  }
}

class _WishCard extends StatelessWidget {
  final AppTheme theme;
  final String title;
  final String preview;
  final bool enabled;
  final int? waitingYears;
  final VoidCallback onTap;

  const _WishCard({
    required this.theme,
    required this.title,
    required this.preview,
    required this.enabled,
    required this.waitingYears,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = theme.wishes;
    final on = palette.onPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: on.withValues(alpha: 0.95),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: enabled
                        ? palette.accent.withValues(alpha: 0.18)
                        : on.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: enabled
                          ? palette.accent.withValues(alpha: 0.4)
                          : on.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    enabled ? 'Enabled' : 'Draft',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? palette.onPrimary.withValues(alpha: 0.95)
                          : on.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              preview.isEmpty ? '(No content)' : preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: on.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (waitingYears != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 16,
                    color: on.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$waitingYears year${waitingYears == 1 ? '' : 's'} waiting',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: on.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppTheme theme;

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    final palette = theme.wishes;
    final on = palette.onPrimary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 56,
              color: on.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No Last Wishes Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: on,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first message for the future.\nIt will stay safe until the right time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: on.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
