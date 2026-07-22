import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/arb/app_localizations.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/prayer_labels.dart';
import '../../../data/models/prayer.dart';
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
    final isJumuah = slot.name == PrayerName.jumuah;
    final time = DateFormat.Hm(locale).format(slot.dateTimeOn(day.date));
    final iqamah = slot.iqamah;
    final iqamahLabel = iqamah == null
        ? null
        : DateFormat.Hm(locale).format(
            DateTime(
              day.date.year,
              day.date.month,
              day.date.day,
              iqamah.hour,
              iqamah.minute,
            ),
          );
    final highlight = isJumuah || isNext;
    final tint = isJumuah ? BrandColors.accent : BrandColors.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: highlight ? tint.withValues(alpha: 0.08) : BrandColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? tint.withValues(alpha: 0.28) : BrandColors.border,
        ),
      ),
      child: Row(
        children: [
          _PrayerIcon(name: slot.name, active: highlight, tint: tint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  prayerLabel(l10n, slot.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: BrandColors.textPrimary,
                    fontSize: 15,
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (iqamahLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${l10n.iqamah} $iqamahLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: BrandColors.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _TimePill(
            label: time,
            sublabel: iqamahLabel == null ? null : l10n.adhan,
            active: highlight,
            tint: tint,
          ),
        ],
      ),
    );
  }
}

class _PrayerIcon extends StatelessWidget {
  const _PrayerIcon({
    required this.name,
    required this.active,
    required this.tint,
  });

  final PrayerName name;
  final bool active;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? tint.withValues(alpha: 0.14) : BrandColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _iconFor(name),
        size: 18,
        color: active ? tint : BrandColors.textMuted,
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
      case PrayerName.jumuah:
        return Icons.mosque_outlined;
    }
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({
    required this.label,
    required this.active,
    required this.tint,
    this.sublabel,
  });

  final String label;
  final String? sublabel;
  final bool active;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? tint.withValues(alpha: 0.12) : BrandColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (sublabel != null)
            Text(
              sublabel!.toUpperCase(),
              style: TextStyle(
                color: active ? tint : BrandColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          Text(
            label,
            style: TextStyle(
              color: active ? tint : BrandColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
