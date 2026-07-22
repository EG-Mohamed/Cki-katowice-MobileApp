import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/utils/hijri_date.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/locale_controller.dart';
import '../../state/prayer_controller.dart';
import '../../state/prayer_notification_coordinator.dart';
import '../../state/settings_controller.dart';
import '../../state/theme_controller.dart';
import 'widgets/next_prayer_hero.dart';
import 'widgets/prayer_row.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _loadDate(BuildContext context, DateTime date) async {
    await context.read<PrayerController>().load(date: date);
  }

  Future<void> _changeLocale(BuildContext context, Locale locale) async {
    final localeController = context.read<LocaleController>();
    await localeController.setLocale(locale);
    if (!context.mounted) return;
    final prayer = context.read<PrayerController>();
    await prayer.load(date: prayer.selectedDate);
    if (!context.mounted || !prayer.isSelectedDateToday) return;
    await context.read<PrayerNotificationCoordinator>().synchronize(
      force: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<PrayerController>();
    final day = controller.day;
    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: day == null
            ? RefreshIndicator(
                onRefresh: () => _loadDate(context, controller.selectedDate),
                child: LayoutBuilder(
                  builder: (context, constraints) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: constraints.maxHeight,
                        child: Center(
                          child: Text(
                            controller.hasError
                                ? l10n.prayerTimesUnavailable
                                : l10n.loading,
                            style: TextStyle(color: BrandColors.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => _loadDate(context, controller.selectedDate),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Greeting(
                        l10n: l10n,
                        onLocaleSelected: (locale) =>
                            _changeLocale(context, locale),
                      ),
                    ),
                    const SliverToBoxAdapter(child: NextPrayerHero()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: _ScheduleHeader(
                          day: day.date,
                          loading: controller.isLoading,
                          onPrevious: () => _loadDate(
                            context,
                            day.date.subtract(const Duration(days: 1)),
                          ),
                          onNext: () => _loadDate(
                            context,
                            day.date.add(const Duration(days: 1)),
                          ),
                          onPick: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: day.date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 730),
                              ),
                            );
                            if (picked != null && context.mounted) {
                              await _loadDate(context, picked);
                            }
                          },
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      sliver: SliverList.separated(
                        itemCount: day.slots.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final slot = day.slots[i];
                          return PrayerRow(
                            slot: slot,
                            isNext: controller.nextPrayer?.name == slot.name,
                          );
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).bottom + 110,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.l10n, required this.onLocaleSelected});
  final AppLocalizations l10n;
  final ValueChanged<Locale> onLocaleSelected;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final languageCode = Localizations.localeOf(context).languageCode;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final gregorian = DateFormat.yMMMMEEEEd(locale).format(now);
    final hijri = HijriDate.fromGregorian(now).format(languageCode);
    final site = context.watch<SettingsController>().settings;
    final name = site?.name.isNotEmpty == true ? site!.name : l10n.mosqueName;
    final logo = site?.logo ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Row(
        children: [
          _Logo(logo: logo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(context, size: 17).copyWith(
                    color: BrandColors.primary,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$hijri  ·  $gregorian',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: BrandColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _LanguageButton(onSelected: onLocaleSelected),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.logo});

  final String logo;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final fallback = Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BrandColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.mosque, color: BrandColors.primary, size: 22),
    );
    if (logo.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        logo,
        width: 46,
        height: 46,
        cacheWidth: 144,
        cacheHeight: 144,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.onSelected});

  final ValueChanged<Locale> onSelected;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final current = context.watch<LocaleController>().locale.languageCode;
    final options = [
      (const Locale('en'), l10n.english),
      (const Locale('pl'), l10n.polish),
      (const Locale('ar'), l10n.arabic),
    ];
    return PopupMenuButton<Locale>(
      tooltip: l10n.language,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(
            value: option.$1,
            child: Row(
              children: [
                Text(option.$2),
                const Spacer(),
                if (current == option.$1.languageCode)
                  Icon(Icons.check, color: BrandColors.accent, size: 18),
              ],
            ),
          ),
      ],
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BrandColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BrandColors.border),
        ),
        child: Icon(Icons.language, color: BrandColors.primary, size: 20),
      ),
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.day,
    required this.loading,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime day;
  final bool loading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMMEEEEd(locale).format(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.todaySchedule),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: BrandColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BrandColors.border),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.previousDay,
                onPressed: loading ? null : onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: loading ? null : onPick,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      date,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: BrandColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.nextDay,
                onPressed: loading ? null : onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
