// lib/pages/future/future_letter_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/future/future_letter_provider.dart';
import 'package:lifecapsule8_app/provider/future/future_letter_draft.dart';

class FutureLetterListPage extends ConsumerWidget {
  const FutureLetterListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(futureLetterProvider);
    final list = st.futureLetterList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('To the Future'),
        actions: [
          IconButton(
            tooltip: 'New',
            onPressed: () async {
              ref.read(futureLetterProvider.notifier).ensureCurrentDraft();
              if (!context.mounted) return;
              Navigator.pushNamed(context, '/FutureLetterWritePage');
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: list.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mail_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      '还没有 Future Letters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('点右上角 + 新建一封。', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 220,
                      child: FilledButton.icon(
                        onPressed: () async {
                          ref
                              .read(futureLetterProvider.notifier)
                              .ensureCurrentDraft();
                          if (!context.mounted) return;
                          Navigator.pushNamed(
                            context,
                            '/FutureLetterWritePage',
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('New letter'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (_, i) => _FutureLetterTile(draft: list[i]),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: list.length,
            ),
    );
  }
}

class _FutureLetterTile extends ConsumerWidget {
  final FutureLetterDraft draft;
  const _FutureLetterTile({required this.draft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipient = (draft.nickname ?? '').trim().isNotEmpty
        ? (draft.nickname ?? '').trim()
        : (draft.toName ?? '').trim().isNotEmpty
        ? (draft.toName ?? '').trim()
        : (draft.userCode ?? '').trim().isNotEmpty
        ? (draft.userCode ?? '').trim()
        : (draft.email ?? '').trim().isNotEmpty
        ? (draft.email ?? '').trim()
        : '未设置收件人';

    final sendAt = (draft.sendAtIso ?? '').trim().isNotEmpty
        ? (draft.sendAtIso ?? '').trim()
        : '未设置时间';

    return Material(
      borderRadius: BorderRadius.circular(14),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ref
              .read(futureLetterProvider.notifier)
              .setCurrentByNoteId(draft.noteId);
          Navigator.pushNamed(context, '/FutureLetterWritePage');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipient,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Send at: $sendAt',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Updated: ${draft.updatedAt}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    ref
                        .read(futureLetterProvider.notifier)
                        .setCurrentByNoteId(draft.noteId);
                    if (!context.mounted) return;
                    Navigator.pushNamed(context, '/FutureLetterWritePage');
                  }
                  if (v == 'delete') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete?'),
                        content: const Text('删除后不可恢复。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (ok != true) return;

                    // ✅ 删除指定 noteId：先 set current，再 deleteCurrent（沿用你已有API）
                    ref
                        .read(futureLetterProvider.notifier)
                        .setCurrentByNoteId(draft.noteId);
                    await ref
                        .read(futureLetterProvider.notifier)
                        .deleteCurrent();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
