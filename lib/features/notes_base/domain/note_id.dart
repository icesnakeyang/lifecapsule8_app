class NoteId {
  static String newId([String prefix = 'n']) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  static String newFutureLetter() {
    return newId('future');
  }

  static String newNote() {
    return newId('note');
  }

  static String newLoveLetter() {
    return newId('love');
  }

  static String newLastWish() {
    return newId('wish');
  }

  static String newPrivateNote() => newId('pivate');

  static bool isFutureLetter(String id) => id.startsWith('future_');
}
