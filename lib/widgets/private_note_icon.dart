import 'dart:math' as math;
import 'package:flutter/material.dart';

class PrivateNoteIcon extends StatelessWidget {
  const PrivateNoteIcon({
    super.key,
    this.size = 32,
    this.color = const Color(0xFF2E2E2E),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PrivateNoteIconPainter(color)),
    );
  }
}

class _PrivateNoteIconPainter extends CustomPainter {
  _PrivateNoteIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    // ===== Notebook =====
    final notebook = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.1,
        size.width * 0.8,
        size.height * 0.8,
      ),
      Radius.circular(size.width * 0.18),
    );

    canvas.drawRRect(notebook, fill);
    canvas.drawRRect(notebook, stroke);

    // Spine
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.18),
      Offset(size.width * 0.22, size.height * 0.82),
      stroke,
    );

    // ===== Lock body =====
    final lockBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.52,
        size.height * 0.55,
        size.width * 0.26,
        size.height * 0.22,
      ),
      Radius.circular(size.width * 0.06),
    );

    canvas.drawRRect(lockBody, fill);
    canvas.drawRRect(lockBody, stroke);

    // Keyhole
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.66),
      size.width * 0.03,
      Paint()..color = color.withOpacity(0.6),
    );

    // ===== Lock shackle =====
    final shackleRect = Rect.fromLTWH(
      size.width * 0.55,
      size.height * 0.42,
      size.width * 0.20,
      size.height * 0.20,
    );

    canvas.drawArc(shackleRect, math.pi, math.pi, false, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
