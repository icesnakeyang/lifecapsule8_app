import 'dart:async' as async;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClockWidget extends ConsumerStatefulWidget {
  const ClockWidget({super.key});

  @override
  ConsumerState<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends ConsumerState<ClockWidget> {
  late DateTime _currentTime;
  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    async.Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String formattedTime(BuildContext context) {
    return "${_currentTime.year}Year"
        "${_currentTime.month}Month"
        "${_currentTime.day}Day"
        "${_currentTime.hour.toString().padLeft(2, '0')}Hour"
        "${_currentTime.minute.toString().padLeft(2, '0')}Minute"
        "${_currentTime.second.toString().padLeft(2, '0')}Second";
  }

  @override
  Widget build(BuildContext context) {
    return Text(formattedTime(context), style: const TextStyle(fontSize: 24));
  }
}
