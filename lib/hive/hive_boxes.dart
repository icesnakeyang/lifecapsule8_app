/// 统一管理 Hive 的 box 名称，避免写死字符串
class HiveBoxes {
  /// 笔记存储（加密后的笔记）
  static const String notes = 'notes_box';

  /// 加密相关配置（助记词存在与否、masterKey、salt 等）
  static const String crypto = 'crypto';

  static const loveLetterDrafts = 'love_letter_drafts';

  static const sendTasks = 'send_tasks';
  static const lastWishes = 'last_wishes_box';
  static const inspirationBox = 'inspiration_box';
  static const futureBox = 'future_box';
  static const outbox = 'outbox_box';
}
