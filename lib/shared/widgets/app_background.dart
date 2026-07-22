import 'package:flutter/material.dart';

import '../../core/theme/brand_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(color: BrandColors.scaffold, child: child);
  }
}
