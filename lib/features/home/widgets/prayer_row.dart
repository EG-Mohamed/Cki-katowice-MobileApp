import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/arb/app_localizations.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/prayer_labels.dart';
import '../../../data/models/prayer.dart';
import '../../../state/notification_controller.dart';
import '../../../state/prayer_controller.dart';

class PrayerRow extends StatelessWidget {
  const PrayerRow({super.key, required this.slot, required this.isNext});

  final PrayerSlot slot;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final controller = context.read<PrayerController>();
    final day = controller.day!;
    final time = DateFormat.Hm(locale).format(slot.dateTimeOn(day.date));
    final notif = context.watch<NotificationController>();
    final canNotify =
        controller.isSelectedDateToday && slot.name != PrayerName.sunrise;

    final notificationOn = notif.isEnabled(slot.name);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: isNext
            ? BrandColors.primary.withValues(alpha: 0.08)
            : BrandColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNext
              ? BrandColors.primary.withValues(alpha: 0.22)
              : BrandColors.border,
        ),
      ),
      child: Row(
        children: [
          _PrayerIcon(name: slot.name, active: isNext),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              prayerLabel(l10n, slot.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: BrandColors.textPrimary,
                fontSize: 15,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _TimePill(label: time, active: isNext),
          const SizedBox(width: 6),
          if (canNotify)
            _NotificationButton(
              enabled: notificationOn,
              tooltip: notificationOn ? l10n.adhanOn : l10n.adhanOff,
              onPressed: () => notif.toggle(slot.name),
            )
          else
            const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }
}

class _PrayerIcon extends StatelessWidget {
  const _PrayerIcon({required this.name, required this.active});

  final PrayerName name;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? BrandColors.primary.withValues(alpha: 0.12)
            : BrandColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _iconFor(name),
        size: 18,
        color: active ? BrandColors.primary : BrandColors.textMuted,
      ),
    );
  }

  IconData _iconFor(PrayerName name) {
    switch (name) {
      case PrayerName.fajr:
        return Icons.wb_twilight;
      case PrayerName.sunrise:
        return Icons.wb_sunny_outlined;
      case PrayerName.dhuhr:
        return Icons.light_mode_outlined;
      case PrayerName.asr:
        return Icons.wb_cloudy_outlined;
      case PrayerName.maghrib:
        return Icons.nights_stay_outlined;
      case PrayerName.isha:
        return Icons.dark_mode_outlined;
    }
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? BrandColors.primary.withValues(alpha: 0.12)
            : BrandColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? BrandColors.primary : BrandColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.enabled,
    required this.tooltip,
    required this.onPressed,
  });

  final bool enabled;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(
          enabled ? Icons.notifications_active : Icons.notifications_none,
          size: 18,
          color: enabled ? BrandColors.accent : BrandColors.textMuted,
        ),
      ),
    );
  }
}
