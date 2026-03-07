/// Onboarding / Tips related shared preference keys.
/// Keep it in app/ (UI layer) because it is purely UX behavior.
abstract class OnboardingKeys {
  const OnboardingKeys._();

  // ===== Sections (features) =====
  static const String privateNote = 'private_note';
  static const String loveLetter = 'love_letter';
  static const String futureLetter = 'future_letter';
  static const String inspiration = 'inspiration';

  // ===== Key Builders =====
  /// How many times user entered a feature page.
  static String entryCountKey(String section) =>
      'onboarding.$section.entryCount';

  /// Whether tip dialog is permanently marked as shown.
  static String tipShownKey(String section) => 'onboarding.$section.tipShown';

  /// Optional: last time tip was shown (for cooldown strategies).
  static String lastShownAtMsKey(String section) =>
      'onboarding.$section.lastShownAtMs';
}
