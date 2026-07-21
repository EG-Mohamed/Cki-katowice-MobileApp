import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/brand_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: BrandColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTheme.display(
            context,
            size: 22,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}
