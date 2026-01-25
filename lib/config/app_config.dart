class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8048/lifecapsule8_api/',
    // defaultValue: 'https://gogoyang.com/lifecapsule8_api/',
    // defaultValue: 'https://gogorpg.com/lifecapsule8_api/',
  );

  static const Duration timeout = Duration(seconds: 15);
}
