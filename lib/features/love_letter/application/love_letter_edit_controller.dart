import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/features/love_letter/application/love_letter_list_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:lifecapsule8_app/features/notes_base/application/notes_providers.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_base.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';

final loveLetterEditControllerProvider =
    AsyncNotifierProvider<LoveLetterEditController, LoveLetterEditState>(
      LoveLetterEditController.new,
    );

class LoveLetterEditState {
  final bool isLoading;
  final bool isSaving;
  final NoteBase? note;
  final bool isPersisted;
  final String? error;

  const LoveLetterEditState({
    this.isLoading = true,
    this.isSaving = false,
    this.note,
    this.isPersisted = false,
    this.error,
  });

  LoveLetterEditState copyWith({
    bool? isLoading,
    bool? isSaving,
    NoteBase? note,
    bool? isPersisted,
    String? error,
    bool clearError = false,
  }) {
    return LoveLetterEditState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      note: note ?? this.note,
      isPersisted: isPersisted ?? this.isPersisted,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LoveLetterEditController extends AsyncNotifier<LoveLetterEditState> {
  final _uuid = const Uuid();

  @override
  Future<LoveLetterEditState> build() async {
    return const LoveLetterEditState(isLoading: true);
  }

  /// 打开一封信（新建或加载已有）
  Future<void> open({String? noteId}) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(notesRepositoryProvider);
      NoteBase? note;
      bool persisted = false;

      if (noteId != null) {
        note = await repo.getById(noteId);
        if (note != null) {
          persisted = true;
        } else {
          note = null;
        }
      }

      note ??= _newDraft();

      state = AsyncData(
        LoveLetterEditState(
          isLoading: false,
          note: note,
          isPersisted: persisted,
        ),
      );
    } catch (e) {
      state = AsyncData(
        LoveLetterEditState(
          isLoading: false,
          error: 'Failed to load letter: $e',
        ),
      );
    }
  }

  /// 更新内容（仅内存中，不保存）
  void setContent(String text) {
    final current = state.value;
    if (current?.note == null) return;

    final updatedNote = current!.note!.copyWith(
      content: text,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    state = AsyncData(current.copyWith(note: updatedNote));
  }

  /// 保存当前信件（自动判断新建/更新/删除）
  Future<void> save() async {
    final current = state.value;
    if (current == null || current.note == null) return;
    if (current.isSaving) return;

    state = AsyncData(current.copyWith(isSaving: true));

    try {
      final repo = ref.read(notesRepositoryProvider);
      final content = (current.note!.content ?? '').trim();

      if (content.isEmpty) {
        if (current.isPersisted) {
          await repo.markDeleted(current.note!.id);
        }
        state = AsyncData(current.copyWith(isSaving: false));
        return;
      }

      final nextVersion = current.isPersisted ? current.note!.version + 1 : 1;
      final toSave = current.note!.copyWith(
        content: content,
        version: nextVersion,
        updatedAt: DateTime.now(),
        isDeleted: false,
        isSynced: false,
      );

      await repo.upsert(toSave);

      state = AsyncData(
        current.copyWith(isSaving: false, isPersisted: true, note: toSave),
      );
    } catch (e) {
      state = AsyncData(
        current.copyWith(isSaving: false, error: 'Save failed: $e'),
      );
    }
  }

  /// 保存或删除（编辑页退出/后台时常用）
  Future<void> saveOrDeleteCurrent(String content) async {
    final currentState = state.value;
    if (currentState == null || currentState.note == null) {
      // 没有有效的 note，直接返回（或记录日志）
      return;
    }

    final trimmed = content.trim();

    if (trimmed.isEmpty) {
      if (currentState.isPersisted) {
        final repo = ref.read(notesRepositoryProvider);
        await repo.markDeleted(currentState.note!.id);
        // 通知列表刷新（如果列表 controller 存在）
        ref.invalidate(loveLetterListControllerProvider);
      }
      // 清空内容（仅内存状态）
      final updatedNote = currentState.note!.copyWith(content: '');
      state = AsyncData(currentState.copyWith(note: updatedNote));
    } else {
      // 非空 → 更新内存并保存
      setContent(content);
      await save();
    }
  }

  /// 获取当前 noteId（方便页面使用）
  String? get currentNoteId => state.value?.note?.id;

  /// 获取当前 note（完整对象）
  NoteBase? get currentNote => state.value?.note;

  NoteBase _newDraft() {
    final now = DateTime.now();
    return NoteBase(
      id: 'love_${_uuid.v4()}',
      userId: '',
      kind: NoteKind.loveLetter,
      createdAt: now,
      updatedAt: now,
      content: '',
      enc: null,
      serverNoteId: null,
      isSynced: false,
      isDeleted: false,
      version: 1,
      meta: {'loveLetter': {}},
    );
  }
}
