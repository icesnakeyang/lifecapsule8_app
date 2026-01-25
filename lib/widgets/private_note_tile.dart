import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lifecapsule8_app/ui/private_note_style.dart';

class PrivateNoteTile extends StatefulWidget {
  const PrivateNoteTile({
    super.key,
    required this.width,
    this.height = 80,
    this.label = 'Private Note',
    required this.onOpen,
    this.radius = 16,
  });

  final double width;
  final double height;
  final String label;
  final VoidCallback onOpen;
  final double radius;

  @override
  State<PrivateNoteTile> createState() => _PrivateNoteTileState();
}

class _PrivateNoteTileState extends State<PrivateNoteTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  bool _busy = false;
  bool _pressed = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_busy) return;
    setState(() => _busy = true);

    await _c.forward();
    widget.onOpen();

    await _c.reverse();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final bg = PrivateNoteStyle.bg(context);
    final border = PrivateNoteStyle.border(context);
    final shadow = PrivateNoteStyle.shadow(context);
    final iconC = PrivateNoteStyle.icon(context);
    final textC = PrivateNoteStyle.text(context);

    final scale = _pressed ? 0.98 : 1.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: _tap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: bg.withOpacity(0.92),
                borderRadius: BorderRadius.circular(widget.radius),
                border: Border.all(color: border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: shadow,
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _t,
                    builder: (_, __) {
                      // 锁扣打开：旋转 + 上移 + 轻微淡出
                      final shackleRot = (-28.0 * _t.value) * math.pi / 180.0;
                      final shackleDy = -4.0 * _t.value;
                      final shackleOpacity = (1.0 - 0.35 * _t.value).clamp(
                        0.0,
                        1.0,
                      );

                      // 锁体轻微下沉一点点，像“解扣”
                      final bodyDy = 1.0 * _t.value;

                      return SizedBox(
                        width: 44,
                        height: 44,
                        child: CustomPaint(
                          painter: _PrivateIconPainter(
                            color: iconC,
                            shackleRot: shackleRot,
                            shackleDy: shackleDy,
                            shackleOpacity: shackleOpacity,
                            bodyDy: bodyDy,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textC,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: textC, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 关键：不要用多个 Icon 叠来叠去，直接画一个统一风格的“笔记本+锁”线条图标
class _PrivateIconPainter extends CustomPainter {
  _PrivateIconPainter({
    required this.color,
    required this.shackleRot,
    required this.shackleDy,
    required this.shackleOpacity,
    required this.bodyDy,
  });

  final Color color;
  final double shackleRot;
  final double shackleDy;
  final double shackleOpacity;
  final double bodyDy;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    // notebook rect
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 7, size.width - 12, size.height - 14),
      const Radius.circular(10),
    );
    canvas.drawRRect(r, fill);
    canvas.drawRRect(r, stroke);

    // notebook spine line
    canvas.drawLine(Offset(13, 12), Offset(13, size.height - 12), stroke);

    // lock body (bottom-right)
    final lockBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.52, size.height * 0.52 + bodyDy, 16, 14),
      const Radius.circular(4),
    );
    canvas.drawRRect(lockBody, Paint()..color = color.withOpacity(0.14));
    canvas.drawRRect(lockBody, stroke);

    // keyhole (tiny)
    final keyhole = Paint()
      ..color = color.withOpacity(0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.60, size.height * 0.59 + bodyDy),
      1.7,
      keyhole,
    );

    // shackle (animated)
    canvas.save();
    final cx = size.width * 0.60;
    final cy = size.height * 0.49 + shackleDy;

    canvas.translate(cx, cy);
    canvas.rotate(shackleRot);
    canvas.translate(-cx, -cy);

    final shacklePaint = Paint()
      ..color = color.withOpacity(shackleOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final shackleRect = Rect.fromLTWH(
      size.width * 0.54,
      size.height * 0.40 + shackleDy,
      12,
      10,
    );
    canvas.drawArc(shackleRect, math.pi, math.pi, false, shacklePaint);
    // shackle legs
    canvas.drawLine(
      Offset(size.width * 0.54, size.height * 0.45 + shackleDy),
      Offset(size.width * 0.54, size.height * 0.52 + shackleDy),
      shacklePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, size.height * 0.45 + shackleDy),
      Offset(size.width * 0.66, size.height * 0.52 + shackleDy),
      shacklePaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PrivateIconPainter old) {
    return old.color != color ||
        old.shackleRot != shackleRot ||
        old.shackleDy != shackleDy ||
        old.shackleOpacity != shackleOpacity ||
        old.bodyDy != bodyDy;
  }
}
