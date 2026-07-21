import 'dart:math' as math;

import 'package:flutter/material.dart';

class GeometricPattern extends StatelessWidget {
  const GeometricPattern({
    super.key,
    required this.color,
    this.opacity = 0.08,
    this.cell = 64,
  });

  final Color color;
  final double opacity;
  final double cell;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GirihPainter(
          color: color.withValues(alpha: opacity),
          cell: cell,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _GirihPainter extends CustomPainter {
  _GirihPainter({required this.color, required this.cell});

  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final r = cell * 0.42;
    for (double y = 0; y <= size.height + cell; y += cell) {
      for (double x = 0; x <= size.width + cell; x += cell) {
        _drawStar(canvas, Offset(x, y), r, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const points = 8;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final rad = isOuter ? radius : radius * 0.45;
      final angle = (math.pi / points) * i - math.pi / 2;
      final p = Offset(
        center.dx + rad * math.cos(angle),
        center.dy + rad * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GirihPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.cell != cell;
}
