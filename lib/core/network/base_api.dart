import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lifecapsule8_app/core/network/api_client.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BaseApi {
  static const int _successCode = 0;
  static const int _tokenInvalidCode = 10005;
  // 避免多次重复跳转登录
  static bool _isHandlingTokenInvalid = false;

  // 所有请求都走这个 post，超级干净！
  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        path,
        data: data,
        options: options,
      );
      final Map<String, dynamic> result = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data);
      final int code = int.tryParse(result['code'].toString()) ?? -1;
      if (code == _successCode) {
        return result;
      }
      if (code == _tokenInvalidCode) {
        _handleTokenInvalid();
        throw TokenInvalidException(result['msg'] ?? 'Token is invalid');
      }
      return result;
    } on DioException catch (e) {
      // ✅ 关键：打印“实际请求的完整主机地址 + path”
      debugPrint('❌ DioException: ${e.type}');
      debugPrint('➡️  ${e.requestOptions.method} ${e.requestOptions.uri}');
      debugPrint('Headers: ${e.requestOptions.headers}');
      debugPrint('Data: ${e.requestOptions.data}');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Resp: ${e.response?.data}');
      final data = e.response?.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return data.cast<String, dynamic>();
      return {'code': 999, 'msg': 'Network error'};
    } catch (_) {
      return {'code': 999901, 'msg': 'error.system'};
    }
  }

  static void _handleTokenInvalid() {
    if (_isHandlingTokenInvalid) return;
    _isHandlingTokenInvalid = true;
    final context = navigatorKey.currentContext;
    if (context == null) {
      _isHandlingTokenInvalid = false;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!context.mounted) return;
        final routeName = ModalRoute.of(context)?.settings.name;
        if (routeName == '/login') return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Login session is expired, please log in again.'),
              backgroundColor: Colors.deepOrange,
              duration: Duration(seconds: 8),
            ),
          );

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      } finally {
        _isHandlingTokenInvalid = false;
      }
    });
  }
}

class TokenInvalidException implements Exception {
  final String message;
  TokenInvalidException(this.message);

  @override
  String toString() => 'TokenInvalidException: $message';
}
