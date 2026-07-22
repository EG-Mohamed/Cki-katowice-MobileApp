import 'package:flutter/material.dart';

import 'brand_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData build(Locale locale, {bool isDark = false}) {
    final bool isArabic = locale.languageCode == 'ar';
    final Brightness brightness = isDark ? Brightness.dark : Brightness.light;
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: BrandColors.primary,
      onPrimary: BrandColors.onPrimary,
      secondary: BrandColors.accent,
      onSecondary: BrandColors.onAccent,
      surface: BrandColors.surface,
      onSurface: BrandColors.textPrimary,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
    );

    final TextTheme base = _textTheme(isArabic);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: BrandColors.scaffold,
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: BrandColors.textPrimary,
        titleTextStyle: _display(isArabic).copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: BrandColors.textPrimary,
        ),
      ),
      iconTheme: IconThemeData(color: BrandColors.textSecondary),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: BrandColors.primary,
        selectionColor: BrandColors.primary.withValues(alpha: 0.20),
        selectionHandleColor: BrandColors.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: BrandColors.primary, width: 1.4),
        ),
      ),
      dividerColor: BrandColors.border,
      cardColor: BrandColors.surface,
      splashColor: BrandColors.primary.withValues(alpha: 0.06),
      highlightColor: BrandColors.primary.withValues(alpha: 0.03),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BrandColors.primary
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BrandColors.primary.withValues(alpha: 0.45)
              : BrandColors.textMuted.withValues(alpha: 0.3),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: BrandColors.textSecondary,
        textColor: BrandColors.textPrimary,
      ),
    );
  }

  static TextTheme _textTheme(bool isArabic) {
    final TextTheme body = Typography.material2021().black.apply(
      fontFamily: isArabic ? 'NotoKufiArabic' : 'Inter',
    );
    return body.apply(
      bodyColor: BrandColors.textPrimary,
      displayColor: BrandColors.textPrimary,
    );
  }

  static TextStyle _display(bool isArabic) {
    return TextStyle(
      fontFamily: isArabic ? 'NotoKufiArabic' : 'Inter',
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle display(BuildContext context, {double? size, Color? color}) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return _display(isArabic).copyWith(
      fontSize: size,
      color: color ?? BrandColors.textPrimary,
      letterSpacing: -0.3,
    );
  }

  static TextStyle arabicQuran({double size = 24, Color? color}) {
    return TextStyle(
      fontFamily: 'Amiri',
      fontSize: size,
      height: 1.9,
      color: color ?? BrandColors.textPrimary,
    );
  }
}
