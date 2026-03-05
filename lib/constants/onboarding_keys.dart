// lib/constants/onboarding_keys.dart

class OnboardingKeys {
  static String tipShownKey(String section) => '${section}_tip_shown';
  static String entryCountKey(String section) => '${section}_entry_count';

  // 方便统一管理所有板块的 key（可选）
  static const String privateNote = 'private_note';
  // static const String loveLetters = 'love_letters';  // 其他板块同理
}