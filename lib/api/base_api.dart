import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lifecapsule8_app/api/api_client.dart';
import 'package:lifecapsule8_app/main.dart';

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
      // 统一处理你的后端返回格式
      return e.response?.data ?? {'code': 999, 'msg': 'Nerwork error'};
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
