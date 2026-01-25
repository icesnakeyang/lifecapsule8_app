import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifecapsule8_app/crypto/crypto_provider.dart';
import 'package:lifecapsule8_app/provider/note/local_note.dart';
import 'package:lifecapsule8_app/provider/note/note_provider.dart';
import 'package:lifecapsule8_app/theme/app_theme.dart';
import 'package:lifecapsule8_app/theme/theme_provider.dart';

class NoteList extends ConsumerStatefulWidget {
  const NoteList({super.key});

  @override
  ConsumerState<NoteList> createState() => _NoteListState();
}

class _NoteListState extends ConsumerState<NoteList> {
  @override
  void initState() {
    super.initState();
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'LOVE_LETTER':
        return Icons.favorite;
      case 'INSPIRATION':
        return Icons.auto_awesome;
      case 'FUTURE_LETTER':
        return Icons.schedule_send;
      case 'WISHES':
        return Icons.volunteer_activism;
      case 'PRIVATE_NOTE':
      default:
        return Icons.note;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'LOVE_LETTER':
        return 'Love';
      case 'INSPIRATION':
        return 'Inspiration';
      case 'FUTURE_LETTER':
        return 'Future';
      case 'WISHES':
        return 'Wishes';
      case 'PRIVATE_NOTE':
      default:
        return 'Note';
    }
  }

  Color? _typeColor(AppTheme theme, String type) {
    switch (type) {
      case 'LOVE_LETTER':
        return theme.error;
      case 'INSPIRATION':
        return theme.primary;
      case 'FUTURE_LETTER':
        return theme.warning;
      case 'WISHES':
        return theme.success;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noteProvider);

    final theme = ref.watch(themeProvider);
    final crypto = ref.watch(cryptoProvider);
    final isEncrypted = crypto.hasMnemonic && crypto.hasMasterKey;

    final List<LocalNote> notes = state.notes
        .where((n) => n.type == 'PRIVATE_NOTE')
        .toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text(
            "My Private Notes",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                final notifier = ref.read(noteProvider.notifier);
                notifier.clearCurrentNote();
                navigator.pushNamed('/noteedit');
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: notes.isEmpty
            ? const Center(child: Text("No notes yet"))
            : ListView.separated(
                itemCount: notes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = notes[index];
                  final content = item.content;
                  final updatedAt = item.updatedAt;

                  final title = content.trim().split("\n").first.trim();
                  final type = item.type;

                  final chipColor = _typeColor(theme, type);

                  return ListTile(
                    leading: Icon(_typeIcon(type), color: chipColor),
                    title: Text(
                      title.isEmpty ? "(Empty note)" : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      DateFormat.yMd().add_Hm().format(updatedAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Chip(
                      label: Text(
                        _typeLabel(type),
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: chipColor?.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: (chipColor ?? theme.divider).withValues(
                          alpha: 0.35,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                    onTap: () {
                      ref
                          .read(noteProvider.notifier)
                          .setCurrentNoteById(item.id);
                      Navigator.pushNamed(
                        context,
                        '/noteedit',
                        arguments: {'id': item.id, 'content': item.content},
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
