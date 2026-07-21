import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/utils/prayer_labels.dart';
import '../../data/services/notification_service.dart';
import '../../state/locale_controller.dart';
import '../../state/notification_controller.dart';
import '../../state/prayer_controller.dart';
import '../../state/settings_controller.dart';
import '../../state/theme_controller.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/about_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _reschedule(BuildContext context) async {
    final prayer = context.read<PrayerController>();
    final notif = context.read<NotificationController>();
    final service = context.read<NotificationService>();
    final l10n = AppLocalizations.of(context);
    final day = prayer.day;
    if (day == null) return;
    if (notif.enabled.isEmpty) {
      await service.cancelAll();
      return;
    }
    await service.requestPermission();
    await service.scheduleForDay(
      day: day,
      enabled: notif.enabled,
      title: l10n.notificationTitle,
      titleFor: (name) => l10n.notificationBody(prayerLabel(l10n, name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = context.watch<LocaleController>();
    final notif = context.watch<NotificationController>();
    final theme = context.watch<ThemeController>();
    final site = context.watch<SettingsController>().settings;

    return AppBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(l10n.settings, style: AppTheme.display(context, size: 30)),
            const SizedBox(height: 24),
            SectionHeader(title: l10n.language),
            const SizedBox(height: 12),
            _LanguagePicker(
              current: locale.locale,
              onSelect: (value) async {
                await locale.setLocale(value);
                if (context.mounted) {
                  await context.read<PrayerController>().load();
                }
                if (context.mounted &&
                    context.read<PrayerController>().isSelectedDateToday) {
                  await _reschedule(context);
                }
              },
              l10n: l10n,
            ),
            const SizedBox(height: 28),
            SectionHeader(title: l10n.appearance),
            const SizedBox(height: 12),
            _Card(
              child: _ToggleRow(
                title: l10n.darkMode,
                subtitle: l10n.darkModeDesc,
                value: theme.isDark,
                onChanged: theme.setDark,
              ),
            ),
            const SizedBox(height: 28),
            SectionHeader(title: l10n.notifications),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                children: [
                  _ToggleRow(
                    title: l10n.prayerNotifications,
                    subtitle: l10n.prayerNotificationsDesc,
                    value: notif.allEnabled,
                    onChanged: (v) async {
                      await notif.setAll(v);
                      if (context.mounted) await _reschedule(context);
                    },
                  ),
                  Divider(color: BrandColors.border, height: 24),
                  for (final name in NotificationController.notifiable)
                    _ToggleRow(
                      title: prayerLabel(l10n, name),
                      value: notif.isEnabled(name),
                      onChanged: (_) async {
                        await notif.toggle(name);
                        if (context.mounted) await _reschedule(context);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SectionHeader(title: l10n.about),
            const SizedBox(height: 12),
            AboutSection(
              settings: site,
              fallbackName: l10n.mosqueName,
              fallbackBody: l10n.aboutBody,
            ),
            const SizedBox(height: 24),
            const _CreditFooter(),
          ],
        ),
      ),
    );
  }
}

class _CreditFooter extends StatelessWidget {
  const _CreditFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => launchUrl(
          Uri.parse('https://msaied.com/'),
          mode: LaunchMode.externalApplication,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              Text(
                'Built with ',
                style: TextStyle(color: BrandColors.textMuted, fontSize: 12),
              ),
              Icon(Icons.favorite, color: BrandColors.accent, size: 13),
              Text(
                ' by ',
                style: TextStyle(color: BrandColors.textMuted, fontSize: 12),
              ),
              Text(
                'Mohamed Said',
                style: TextStyle(
                  color: BrandColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({
    required this.current,
    required this.onSelect,
    required this.l10n,
  });

  final Locale current;
  final ValueChanged<Locale> onSelect;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final options = [
      (const Locale('en'), l10n.english),
      (const Locale('pl'), l10n.polish),
      (const Locale('ar'), l10n.arabic),
    ];
    return _Card(
      child: Column(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i > 0) Divider(color: BrandColors.border, height: 20),
            InkWell(
              onTap: () => onSelect(options[i].$1),
              child: Row(
                children: [
                  Text(
                    options[i].$2,
                    style: TextStyle(color: BrandColors.textPrimary),
                  ),
                  const Spacer(),
                  if (current.languageCode == options[i].$1.languageCode)
                    Icon(
                      Icons.check_circle,
                      color: BrandColors.accent,
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.circle_outlined,
                      color: BrandColors.textMuted,
                      size: 20,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: BrandColors.textPrimary)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(color: BrandColors.textMuted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandColors.border),
      ),
      child: child,
    );
  }
}
