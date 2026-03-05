import 'package:dio/dio.dart';
import 'package:lifecapsule8_app/config/app_config.dart';
import 'package:lifecapsule8_app/global/global_device.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.timeout,
      receiveTimeout: AppConfig.timeout,
      contentType: 'application/json',
    ),
  );

  static Future<void> init() async {
    print('🚀 当前使用的 baseUrl: ${AppConfig.baseUrl}');  // <--- 加这行
    final prefs = await SharedPreferences.getInstance();

    _dio.interceptors.clear();

    // 全局自动加 token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = prefs.getString('token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['X-LC-Device-Id'] = GlobalDevice.deviceId;
          // ⭐⭐ 打印完整请求 URL ⭐⭐
          print(
            '🌐 API Request: ${options.method} ${options.baseUrl}${options.path}',
          );
          print('Headers: ${options.headers}');
          print('Data: ${options.data}');
          handler.next(options);
        },
        onError: (e, handler) {
          // 统一错误处理（可扩展网络错误、401 自动重登等）
          print('API Error: ${e.response?.data ?? e.message}');
          handler.next(e);
        },
      ),
    );
  }

  static Dio get instance => _dio;
}
