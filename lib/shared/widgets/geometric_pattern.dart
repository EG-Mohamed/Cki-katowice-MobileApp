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
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GirihPainter(
            color: color.withValues(alpha: opacity),
            cell: cell,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _GirihPainter extends CustomPainter {
  _GirihPainter({required this.color, required this.cell})
    : _star = _buildStar(cell * 0.42);

  final Color color;
  final double cell;
  final Path _star;

  static Path _buildStar(double radius) {
    const points = 8;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final rad = isOuter ? radius : radius * 0.45;
      final angle = (math.pi / points) * i - math.pi / 2;
      final p = Offset(rad * math.cos(angle), rad * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (double y = 0; y <= size.height + cell; y += cell) {
      for (double x = 0; x <= size.width + cell; x += cell) {
        canvas.save();
        canvas.translate(x, y);
        canvas.drawPath(_star, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_GirihPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.cell != cell;
}
