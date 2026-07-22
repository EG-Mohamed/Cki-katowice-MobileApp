import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../../core/localization/arb/app_localizations.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/prayer_labels.dart';
import '../../../shared/widgets/geometric_pattern.dart';
import '../../../state/prayer_controller.dart';
import '../../../state/theme_controller.dart';

class NextPrayerHero extends StatelessWidget {
  const NextPrayerHero({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<PrayerController>();
    final next = controller.nextPrayer;
    final day = controller.day;
    if (!controller.isSelectedDateToday || next == null || day == null) {
      return const SizedBox.shrink();
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    final timeLabel = DateFormat.Hm(locale).format(next.dateTimeOn(day.date));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.hero),
              ),
            ),
            const Positioned.fill(
              child: GeometricPattern(
                color: Colors.white,
                opacity: 0.07,
                cell: 44,
              ),
            ),
            Positioned(
              right: -26,
              top: -26,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.glow,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.nextPrayer.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prayerLabel(l10n, next.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.display(context, size: 22).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ValueListenableBuilder<Duration>(
                    valueListenable: controller.remainingListenable,
                    builder: (context, remaining, _) =>
                        _Countdown(remaining: remaining),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: BrandColors.accentLight.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: BrandColors.accentLight,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining});
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [_unit(h), _sep(), _unit(m), _sep(), _unit(s)],
      ),
    );
  }

  Widget _unit(int value) {
    return Text(
      value.toString().padLeft(2, '0'),
      style: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _sep() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Text(
      ':',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 18,
        fontWeight: FontWeight.w400,
      ),
    ),
  );
}
