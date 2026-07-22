import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/brand_colors.dart';
import '../../state/theme_controller.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Material(color: BrandColors.scaffold, child: child);
  }
}
