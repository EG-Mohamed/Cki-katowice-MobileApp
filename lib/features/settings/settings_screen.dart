import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand_colors.dart';
import '../../state/locale_controller.dart';
import '../../state/prayer_controller.dart';
import '../../state/prayer_notification_coordinator.dart';
import '../../state/settings_controller.dart';
import '../../state/theme_controller.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/about_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = context.watch<LocaleController>();
    final notif = context.watch<PrayerNotificationCoordinator>();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: BrandColors.accentSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: BrandColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.prayerNotifications,
                              style: TextStyle(
                                color: BrandColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.prayerNotificationsDesc,
                              style: TextStyle(
                                color: BrandColors.textMuted,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(color: BrandColors.border, height: 24),
                  _NotificationStatus(
                    status: notif.status,
                    onFix:
                        notif.status.permission ==
                            PrayerNotificationPermission.denied
                        ? () async {
                            await openAppSettings();
                          }
                        : (!notif.status.exactAlarmAvailable
                              ? notif.requestExactAlarmAccess
                              : null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SectionHeader(title: l10n.quickActions),
            const SizedBox(height: 12),
            _Card(child: _QuickAccess()),
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

class _NotificationStatus extends StatelessWidget {
  const _NotificationStatus({required this.status, this.onFix});

  final PrayerNotificationStatus status;
  final Future<void> Function()? onFix;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final (icon, color, message) = switch (status.syncState) {
      PrayerNotificationSyncState.syncing => (
        Icons.sync,
        BrandColors.textMuted,
        l10n.notificationSyncing,
      ),
      PrayerNotificationSyncState.failed => (
        Icons.error_outline,
        Theme.of(context).colorScheme.error,
        l10n.notificationScheduleFailed,
      ),
      _ when status.permission == PrayerNotificationPermission.denied => (
        Icons.notifications_off_outlined,
        Theme.of(context).colorScheme.error,
        l10n.notificationPermissionDenied,
      ),
      _ when !status.exactAlarmAvailable => (
        Icons.schedule,
        BrandColors.accent,
        l10n.notificationDelayedHint,
      ),
      _ when status.scheduledThrough != null => (
        Icons.check_circle_outline,
        BrandColors.accent,
        l10n.notificationScheduled(
          status.scheduledCount,
          MaterialLocalizations.of(
            context,
          ).formatCompactDate(status.scheduledThrough!),
        ),
      ),
      _ => (
        Icons.info_outline,
        BrandColors.textMuted,
        l10n.prayerNotificationsDesc,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: color, fontSize: 12, height: 1.35),
              ),
            ),
          ],
        ),
        if (onFix != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onFix,
              child: Text(l10n.openSystemSettings),
            ),
          ),
      ],
    );
  }
}

class _CreditFooter extends StatelessWidget {
  const _CreditFooter();

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
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
    context.watch<ThemeController>();
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
    context.watch<ThemeController>();
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

class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final entries = [
      _QuickEntry(Icons.explore_outlined, l10n.qiblaDirection, '/qibla', true),
      _QuickEntry(
        Icons.record_voice_over_outlined,
        l10n.khutbaTitle,
        '/khutba',
        true,
      ),
      _QuickEntry(Icons.article_outlined, l10n.newsAnnouncements, '/news', false),
      _QuickEntry(Icons.menu_book_outlined, l10n.quranReader, '/quran', false),
    ];
    return Column(
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          if (i > 0) Divider(color: BrandColors.border, height: 20),
          _QuickRow(entry: entries[i]),
        ],
      ],
    );
  }
}

class _QuickEntry {
  const _QuickEntry(this.icon, this.label, this.route, this.push);
  final IconData icon;
  final String label;
  final String route;
  final bool push;
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({required this.entry});
  final _QuickEntry entry;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => entry.push
          ? context.push(entry.route)
          : context.go(entry.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BrandColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(entry.icon, color: BrandColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.label,
                style: TextStyle(
                  color: BrandColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: BrandColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
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
