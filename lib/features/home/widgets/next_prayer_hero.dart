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

class NextPrayerHero extends StatelessWidget {
  const NextPrayerHero({super.key});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.hero),
              ),
            ),
            Positioned.fill(
              child: GeometricPattern(
                color: Colors.white,
                opacity: 0.06,
                cell: 46,
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.glow,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.nextPrayer.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          prayerLabel(l10n, next.name),
                          textAlign: TextAlign.center,
                          style: AppTheme.display(context, size: 24).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                        _TimePill(label: timeLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ValueListenableBuilder<Duration>(
                          valueListenable: controller.remainingListenable,
                          builder: (context, remaining, _) =>
                              _Countdown(remaining: remaining),
                        ),
                      ),
                    ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: BrandColors.accentLight.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: BrandColors.accentLight,
          fontSize: 14,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [_unit(h), _sep(), _unit(m), _sep(), _unit(s)],
    );
  }

  Widget _unit(int value) {
    return Text(
      value.toString().padLeft(2, '0'),
      style: TextStyle(
        color: Colors.white,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _sep() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      ':',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 30,
        fontWeight: FontWeight.w400,
      ),
    ),
  );
}
