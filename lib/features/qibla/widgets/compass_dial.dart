import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/brand_colors.dart';
import '../../../data/services/qibla_service.dart';
import '../../../state/theme_controller.dart';

class CompassDial extends StatelessWidget {
  const CompassDial({
    super.key,
    required this.reading,
    required this.alignedLabel,
  });

  final QiblaReading? reading;
  final String alignedLabel;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final aligned = reading?.isAligned ?? false;
    final needle = (reading?.needleAngle ?? 0) * math.pi / 180;
    final heading = (reading?.heading ?? 0) * math.pi / 180;

    return Column(
      children: [
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedRotation(
                turns: -heading / (2 * math.pi),
                duration: const Duration(milliseconds: 200),
                child: CustomPaint(
                  size: const Size(280, 280),
                  painter: _DialPainter(isDark: BrandColors.isDark),
                ),
              ),
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      BrandColors.accent.withValues(
                        alpha: aligned ? 0.28 : 0.10,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              AnimatedRotation(
                turns: needle / (2 * math.pi),
                duration: const Duration(milliseconds: 200),
                child: CustomPaint(
                  size: const Size(220, 220),
                  painter: _NeedlePainter(
                    color: aligned
                        ? BrandColors.accent
                        : BrandColors.accentLight,
                  ),
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BrandColors.surface,
                  border: Border.all(color: BrandColors.accent, width: 1.5),
                ),
                child: Icon(Icons.star, color: BrandColors.accent, size: 24),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AnimatedOpacity(
          opacity: aligned ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: BrandColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                alignedLabel,
                style: TextStyle(
                  color: BrandColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final ring = Paint()
      ..color = BrandColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius - 2, ring);

    final tick = Paint()..color = BrandColors.textMuted;
    for (int i = 0; i < 72; i++) {
      final angle = (i / 72) * 2 * math.pi;
      final isMajor = i % 9 == 0;
      final len = isMajor ? 14.0 : 6.0;
      final p1 =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 4);
      final p2 =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (radius - 4 - len);
      tick.strokeWidth = isMajor ? 2 : 1;
      tick.color = isMajor ? BrandColors.textSecondary : BrandColors.textMuted;
      canvas.drawLine(p1, p2, tick);
    }
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) => oldDelegate.isDark != isDark;
}

class _NeedlePainter extends CustomPainter {
  _NeedlePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(center.dx, 6)
      ..lineTo(center.dx - 14, center.dy - 10)
      ..lineTo(center.dx + 14, center.dy - 10)
      ..close();
    canvas.drawPath(path, paint);

    final tail = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(center.dx, size.height - 20), tail);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => old.color != color;
}
