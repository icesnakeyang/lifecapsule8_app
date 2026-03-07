import 'package:flutter/material.dart';
import 'app_route.dart';
import 'route_registry.dart';

Route<dynamic> appGenerateRoute(RouteSettings settings) {
  final rawName = settings.name ?? '/';
  final uri = Uri.tryParse(rawName);
  final path = uri?.path ?? rawName;

  // 查找匹配的路由
  final matchingRoute = appRoutes.firstWhere(
    (route) => route.name == path,
    orElse: () => AppRoute(
      name: '/unknown',
      builder: (context) => _UnknownPage(name: path),
    ),
  );

  // 合并 arguments + query 参数
  final mergedArgs = _mergeArgs(settings.arguments, uri?.queryParameters);

  return MaterialPageRoute(
    builder: matchingRoute.builder,
    settings: RouteSettings(name: path, arguments: mergedArgs),
  );
}

/// 合并 arguments 与 URL query
Map<String, dynamic>? _mergeArgs(Object? original, Map<String, String>? query) {
  final Map<String, dynamic> base = {};

  if (original is Map) {
    original.forEach((k, v) => base[k.toString()] = v);
  }

  if (query != null) {
    query.forEach((k, v) {
      base[k] = v;
    });
  }

  return base.isEmpty ? null : base;
}

/// 未知页面
class _UnknownPage extends StatelessWidget {
  final String? name;
  const _UnknownPage({this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Route not found: $name')));
  }
}
