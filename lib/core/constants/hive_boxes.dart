abstract class HiveBoxes {
  /// 所有笔记的主表（统一存 NoteBase：content/enc/meta/kind）
  static const String notes = 'notes_box';

  /// 加密相关（助记词是否存在、masterKey 派生信息、创建时间等）
  static const String crypto = 'crypto_box';

  /// 应用设置（主题、语言、开关、onboarding 标记等）
  static const String settings = 'settings_box';

  /// 离线同步 outbox（待上传队列、失败重试、任务状态）
  static const String syncOutbox = 'sync_outbox_box';

  /// 轻量索引（可选）：例如 noteId->kind、最近打开、搜索索引版本号等
  /// 不一定现在就用，但预留语义位
  static const String indexes = 'indexes_box';
}
