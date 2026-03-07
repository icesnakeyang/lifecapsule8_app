import 'package:flutter/material.dart';

class AppRoute {
  final String name;
  final WidgetBuilder builder;
  final bool requireAuth;

  const AppRoute({
    required this.name,
    required this.builder,
    this.requireAuth = false,
  });
}
