abstract class NoteId {
  static String newId() {
    // Hive key 用字符串足够，微秒级基本不撞
    return 'n_${DateTime.now().microsecondsSinceEpoch}';
  }
}
