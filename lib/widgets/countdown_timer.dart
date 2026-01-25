import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/theme/theme_provider.dart';
import 'package:lifecapsule8_app/utils/dt_localized.dart';

class CountdownTimer extends ConsumerStatefulWidget {
  final DateTime targetTime;

  const CountdownTimer({super.key, required this.targetTime});

  @override
  ConsumerState<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends ConsumerState<CountdownTimer> {
  late Timer _timer;
  Duration _duration = Duration.zero;
  bool _isCountingUp = false;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateDuration();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateDuration() {
    final now = DateTime.now();
    setState(() {
      _duration = widget.targetTime.difference(now);
      _isCountingUp = _duration <= Duration.zero;
      if (_isCountingUp) {
        _duration = now.difference(widget.targetTime);
      }
    });
  }

  String _formatUnit(int value) {
    return value.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final days = _duration.inDays;
    final hours = _duration.inHours % 24;
    final minutes = _duration.inMinutes % 60;
    final seconds = _duration.inSeconds % 60;
    final theme = ref.watch(themeProvider);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isCountingUp
              ? [theme.tag1, theme.primary]
              : [theme.secondary, theme.onSecondary],
          // ? [Colors.redAccent.shade100, Colors.redAccent.shade400]
          // : [
          //     Colors.blueAccent.shade100,
          //     const Color.fromARGB(255, 11, 185, 37)
          //   ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isCountingUp ? 'Over time' : 'left',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic, // Center vertically
            children: [
              _buildTimeUnit(days, '天'),
              _buildSeparator(),
              _buildTimeUnit(hours, '小时'),
              _buildSeparator(),
              _buildTimeUnit(minutes, '分'),
              _buildSeparator(),
              _buildTimeUnit(seconds, '秒'),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Over time: ${formatLocalDateTime(context, widget.targetTime)}',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(int value, String label, {Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Color.fromRGBO(0, 0, 0, 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _formatUnit(value),
            style: TextStyle(
              fontSize: 32, // Adjustable font size
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 32, // Match the font size of the digits
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
