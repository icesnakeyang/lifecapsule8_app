/// Last Wishes flow status
enum LastWishesStep {
  intro, // 第1页：引导
  write, // 第2页：写遗言
  destination, // 第3页：去向选择
  recipient, // 第4页：收件人 + 等待周期
  preview, // 第5页：预览确认
  done, // 完成态
}

/// 去向类型
enum LastWishesDestination {
  person, // 发送给某个人（当前唯一可用）
  world, // 公开给全世界（未来开放，当前灰色）
}

/// Last Wishes State（仅描述状态，不含行为）
class LastWishesState {
  final String noteId;

  /// 当前流程所在步骤
  final LastWishesStep step;

  /// 遗言正文
  final String content;

  /// 去向选择
  final LastWishesDestination destination;

  /// 收件人 email（destination == person 时使用）
  final String? recipientEmail;

  /// 等待周期（年）
  final int? waitingYears;

  /// 是否已经确认并启用
  final bool enabled;

  /// 是否正在提交 / 网络请求中
  final bool submitting;

  /// 错误信息（用于页面提示）
  final String? error;

  final String? messageNote;

  const LastWishesState({
    required this.noteId,
    required this.step,
    required this.content,
    required this.destination,
    this.recipientEmail,
    this.waitingYears,
    this.enabled = false,
    this.submitting = false,
    this.error,
    this.messageNote,
  });

  factory LastWishesState.initial({String noteId = 'last_wishes'}) {
    return LastWishesState(
      noteId: noteId,
      step: LastWishesStep.intro,
      content: '',
      destination: LastWishesDestination.person,
      enabled: false,
      submitting: false,
      error: null,
      messageNote: null,
    );
  }

  /// copyWith（后续 Notifier 使用）
  LastWishesState copyWith({
    String? noteId,
    LastWishesStep? step,
    String? content,
    LastWishesDestination? destination,
    String? recipientEmail,
    int? waitingYears,
    bool? enabled,
    bool? submitting,
    String? error,
    bool clearError = false,
    String? messageNote,
    bool clearMessageNote = false,
  }) {
    return LastWishesState(
      noteId: noteId ?? this.noteId,
      step: step ?? this.step,
      content: content ?? this.content,
      destination: destination ?? this.destination,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      waitingYears: waitingYears ?? this.waitingYears,
      enabled: enabled ?? this.enabled,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : error ?? this.error,
      messageNote: clearMessageNote ? null : (messageNote ?? this.messageNote),
    );
  }
}
