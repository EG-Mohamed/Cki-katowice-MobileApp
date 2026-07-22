import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/brand_colors.dart';
import '../../data/models/content.dart';
import '../../state/announcement_controller.dart';
import '../../state/theme_controller.dart';

class AnnouncementBanner extends StatelessWidget {
  const AnnouncementBanner({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final controller = context.watch<AnnouncementController>();
    final announcement = controller.top;
    if (announcement == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final background = _background(announcement.type, context);
    final foreground = _foreground(announcement.type);

    return Material(
      color: background,
      child: InkWell(
        onTap: () => _openDetails(context, announcement, l10n),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Icon(_icon(announcement.type), color: foreground, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label(announcement.type, l10n),
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.75),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      announcement.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.announcementDismiss,
                onPressed: () => controller.dismiss(announcement.id),
                icon: Icon(Icons.close, color: foreground, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(
    BuildContext context,
    Announcement announcement,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: BrandColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _icon(announcement.type),
                      color: _background(announcement.type, context),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _label(announcement.type, l10n),
                      style: TextStyle(
                        color: BrandColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  announcement.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      announcement.body,
                      style: TextStyle(
                        color: BrandColors.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _background(AnnouncementType type, BuildContext context) {
    switch (type) {
      case AnnouncementType.urgent:
        return Theme.of(context).colorScheme.error;
      case AnnouncementType.maintenance:
        return BrandColors.accent;
      case AnnouncementType.general:
        return BrandColors.primary;
    }
  }

  Color _foreground(AnnouncementType type) {
    return type == AnnouncementType.maintenance
        ? BrandColors.onAccent
        : Colors.white;
  }

  IconData _icon(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.urgent:
        return Icons.priority_high;
      case AnnouncementType.maintenance:
        return Icons.build_outlined;
      case AnnouncementType.general:
        return Icons.campaign_outlined;
    }
  }

  String _label(AnnouncementType type, AppLocalizations l10n) {
    switch (type) {
      case AnnouncementType.urgent:
        return l10n.announcementUrgent;
      case AnnouncementType.maintenance:
        return l10n.announcementMaintenance;
      case AnnouncementType.general:
        return l10n.announcementGeneral;
    }
  }
}
