import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/brand_colors.dart';
import '../../state/theme_controller.dart';

class AppHeader extends StatelessWidget {
  const AppHeader.root({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.toolbarHeight,
  }) : leading = null;

  const AppHeader.detail({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.toolbarHeight,
  }) : leading = const BackButton();

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final double? toolbarHeight;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return SliverAppBar(
      pinned: true,
      leading: leading,
      automaticallyImplyLeading: leading != null,
      backgroundColor: BrandColors.scaffold,
      surfaceTintColor: BrandColors.primary,
      scrolledUnderElevation: 4,
      shadowColor: BrandColors.textPrimary.withValues(alpha: 0.14),
      toolbarHeight: toolbarHeight ?? kToolbarHeight,
      title:
          titleWidget ??
          (title == null
              ? null
              : Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(context, size: 20),
                )),
      actions: actions,
    );
  }
}
