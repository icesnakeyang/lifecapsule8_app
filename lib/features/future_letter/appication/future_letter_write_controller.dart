// lib/features/future_letter/application/future_letter_write_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/future_letter/domain/future_letter_draft.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';
import 'future_letter_draft_store.dart';

final futureLetterWriteControllerProvider =
    AsyncNotifierProvider<FutureLetterWriteController, void>(
      FutureLetterWriteController.new,
    );

class FutureLetterWriteController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// ✅ 确保 current draft 存在（只创建内存草稿，避免空内容污染）
  FutureLetterDraft ensureCurrentInMemory({String? noteId}) {
    final storeState = ref.read(futureLetterDraftStoreProvider);
    final cur = storeState.current;
    if (cur != null) {
      if (noteId == null || noteId.isEmpty || cur.noteId == noteId) return cur;
    }

    final now = DateTime.now();
    final d = FutureLetterDraft(
      noteId: (noteId == null || noteId.isEmpty)
          ? 'future_${now.microsecondsSinceEpoch}'
          : noteId,
      updatedAt: now,
      content: '',
    );

    ref.read(futureLetterDraftStoreProvider.notifier).setCurrentInMemory(d);
    return d;
  }

  /// ✅ 打开指定 noteId（从 repo 加载内容到 DraftStore.current）
  Future<FutureLetterDraft> open({String? noteId}) async {
    // 先保证 current 指向正确 noteId（避免用旧 draft 覆盖 UI）
    final cur = ensureCurrentInMemory(noteId: noteId);

    if (noteId == null || noteId.isEmpty) {
      return cur; // 新建
    }

    // 从仓库加载该 noteId 的内容
    final repo = ref.read(notesRepositoryProvider);
    final all = await repo.list(includeDeleted: true);

    final note = all.where((n) => n.id == noteId).isEmpty
        ? null
        : all.firstWhere((n) => n.id == noteId);

    if (note == null) return cur;

    // 可选：校验 kind，避免误打开别的类型
    if (note.kind != NoteKind.futureLetter) return cur;

    final content = (note.content ?? '').trim();

    final meta = (note.meta as Map?) ?? const <String, dynamic>{};

    final sendAtIso = (meta['sendAtIso'] as String?)?.trim();
    final userCode = (meta['userCode'] as String?)?.trim();
    final email = (meta['email'] as String?)?.trim();
    final toName = (meta['toName'] as String?)?.trim();
    final fromName = (meta['fromName'] as String?)?.trim();

    ref
        .read(futureLetterDraftStoreProvider.notifier)
        .setCurrentInMemory(
          FutureLetterDraft(
            noteId: noteId,
            updatedAt: note.updatedAt, // 用 note 自己的时间更合理
            content: content,
            sendAtIso: sendAtIso,
            userCode: userCode,
            email: email,
            toName: toName,
            fromName: fromName,
          ),
        );

    return ref.read(futureLetterDraftStoreProvider).current!;
  }

  /// ✅ 输入时：只更新内存
  void setContentInMemory(String text) {
    ref.read(futureLetterDraftStoreProvider.notifier).setContentInMemory(text);
  }

  /// ✅ 离开 / Next 时：统一 persist（notes_box + 云端/同步链路）
  Future<void> persistBeforeLeave() async {
    await ref
        .read(futureLetterDraftStoreProvider.notifier)
        .persistNowIfNeeded();
  }
}
