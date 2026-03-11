// lib/features/last_wishes/application/last_wishes_state.dart

import 'package:lifecapsule8_app/features/last_wishes/domain/last_wishes_draft.dart';
import 'package:lifecapsule8_app/features/last_wishes/domain/last_wishes_list_item.dart';

class LastWishesState {
  final bool loading;
  final bool saving;
  final bool submitting;
  final bool persisted;

  final String? error;

  /// 当前编辑/预览中的草稿
  final LastWishesDraft draft;

  /// 列表页数据
  final List<LastWishesListItem> items;

  const LastWishesState({
    this.loading = false,
    this.saving = false,
    this.submitting = false,
    this.persisted = false,
    this.error,
    this.draft = const LastWishesDraft(noteId: 'last_wishes'),
    this.items = const [],
  });

  LastWishesState copyWith({
    bool? loading,
    bool? saving,
    bool? submitting,
    bool? persisted,
    String? error,
    bool clearError = false,
    LastWishesDraft? draft,
    List<LastWishesListItem>? items,
  }) {
    return LastWishesState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      submitting: submitting ?? this.submitting,
      persisted: persisted ?? this.persisted,
      error: clearError ? null : (error ?? this.error),
      draft: draft ?? this.draft,
      items: items ?? this.items,
    );
  }

  factory LastWishesState.initial({String noteId = 'last_wishes'}) {
    return LastWishesState(
      loading: false,
      saving: false,
      submitting: false,
      persisted: false,
      error: null,
      draft: LastWishesDraft.empty(noteId: noteId),
      items: const [],
    );
  }

  bool get hasError => (error ?? '').trim().isNotEmpty;

  bool get hasItems => items.isNotEmpty;

  bool get enabled => draft.enabled;

  bool get canGoEditNext => draft.content.trim().isNotEmpty;

  bool get canGoRecipientNext {
    final email = draft.recipientEmail.trim();
    final years = draft.waitingYears;

    if (!_isValidEmail(email)) return false;
    if (years == null) return false;
    if (years < 1) return false;
    return true;
  }

  bool get canConfirm {
    final email = draft.recipientEmail.trim();
    final years = draft.waitingYears;

    if (submitting) return false;
    if (draft.enabled) return false;
    if (draft.content.trim().isEmpty) return false;
    if (!_isValidEmail(email)) return false;
    if (years == null || years < 1) return false;

    return true;
  }

  static bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  @override
  String toString() {
    return 'LastWishesState('
        'loading: $loading, '
        'saving: $saving, '
        'submitting: $submitting, '
        'persisted: $persisted, '
        'error: $error, '
        'draft: $draft, '
        'items: ${items.length}'
        ')';
  }
}
