import 'package:flutter/material.dart';

import 'brand_colors.dart';

class AppGradients {
  AppGradients._();

  static LinearGradient get hero => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      BrandColors.primaryLight,
      BrandColors.primary,
      BrandColors.primaryDark,
    ],
  );

  static LinearGradient get accent => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BrandColors.accentLight, BrandColors.accent],
  );

  static RadialGradient get glow => RadialGradient(
    colors: [
      Colors.white.withValues(alpha: 0.22),
      Colors.white.withValues(alpha: 0.0),
    ],
  );

  static BoxDecoration card({double radius = 16}) => BoxDecoration(
    color: BrandColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: BrandColors.border),
  );
}
