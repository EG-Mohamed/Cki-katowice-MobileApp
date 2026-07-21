import 'package:flutter/material.dart';

class BrandColors {
  BrandColors._();

  static bool isDark = false;

  static const Color primary = Color(0xFF0B7A54);
  static const Color accent = Color(0xFFC9A227);

  static Color get primaryLight => _lighten(primary, 0.10);
  static Color get primaryDark => _darken(primary, 0.08);
  static Color get primarySoft => primary.withValues(alpha: isDark ? 0.18 : 0.10);
  static Color get accentLight => _lighten(accent, 0.10);
  static Color get accentSoft => accent.withValues(alpha: isDark ? 0.22 : 0.14);

  static Color get scaffold =>
      isDark ? const Color(0xFF111512) : const Color(0xFFF7F6F2);
  static Color get surface =>
      isDark ? const Color(0xFF1B211D) : const Color(0xFFFFFFFF);
  static Color get surfaceMuted =>
      isDark ? const Color(0xFF232B26) : const Color(0xFFF1EFE8);
  static Color get border => isDark
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
      : const Color(0xFF1A1A1A).withValues(alpha: 0.08);

  static Color get textPrimary =>
      isDark ? const Color(0xFFF3F5F2) : const Color(0xFF1B241F);
  static Color get textSecondary => textPrimary.withValues(alpha: 0.62);
  static Color get textMuted => textPrimary.withValues(alpha: 0.42);

  static Color get onAccent => const Color(0xFF3A2E08);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
