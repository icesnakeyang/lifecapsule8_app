abstract class LastWishesKeys {
  LastWishesKeys._();
  static const String recipientEmail = 'recipientEmail';
  static const String waitingYears = 'waitingYears';
  static const String enabled = 'enabled';
  static const String messageNote = 'messageNote';

  /// 可选：未来扩展（不影响现在）
  static const String sendMode =
      'sendMode'; // e.g. 'WAIT_YEARS' / 'SPECIFIC_TIME'
  static const String sendAtMs = 'sendAtMs'; // epoch millis
}
