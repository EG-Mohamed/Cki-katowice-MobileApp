import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/arb/app_localizations.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../state/prayer_notification_coordinator.dart';
import '../../../state/theme_controller.dart';

/// Surfaces the two device-level settings that most commonly cause a
/// missed or delayed Adhan — battery optimisation and exact-alarm access —
/// with a one-tap fix for each, plus guidance for OEMs that need an extra
/// "autostart" toggle the OS doesn't expose through a standard permission.
class ReliableAdhanCard extends StatefulWidget {
  const ReliableAdhanCard({super.key, required this.notif});

  final PrayerNotificationCoordinator notif;

  @override
  State<ReliableAdhanCard> createState() => _ReliableAdhanCardState();
}

class _ReliableAdhanCardState extends State<ReliableAdhanCard>
    with WidgetsBindingObserver {
  bool? _ignoringBatteryOptimizations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final value = await widget.notif.isIgnoringBatteryOptimizations();
    if (mounted) setState(() => _ignoringBatteryOptimizations = value);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final status = widget.notif.status;
    final batteryOk = _ignoringBatteryOptimizations ?? true;
    final exactOk = status.exactAlarmAvailable;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandColors.border),
      ),
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
                  color: BrandColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: BrandColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reliableAdhanTitle,
                      style: TextStyle(
                        color: BrandColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.reliableAdhanDesc,
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
          _CheckRow(
            ok: batteryOk,
            okLabel: l10n.batteryOptimizationOff,
            badLabel: l10n.batteryOptimizationOn,
            fixLabel: l10n.batteryOptimizationFix,
            onFix: () async {
              await widget.notif.requestIgnoreBatteryOptimizations();
              await _refresh();
            },
          ),
          const SizedBox(height: 10),
          _CheckRow(
            ok: exactOk,
            okLabel: l10n.exactAlarmOn,
            badLabel: l10n.exactAlarmOff,
            fixLabel: l10n.exactAlarmFix,
            onFix: widget.notif.requestExactAlarmAccess,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.oemAutostartHint,
            style: TextStyle(
              color: BrandColors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.ok,
    required this.okLabel,
    required this.badLabel,
    required this.fixLabel,
    required this.onFix,
  });

  final bool ok;
  final String okLabel;
  final String badLabel;
  final String fixLabel;
  final Future<void> Function() onFix;

  @override
  Widget build(BuildContext context) {
    final color = ok ? BrandColors.primary : BrandColors.accent;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.warning_amber_outlined,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ok ? okLabel : badLabel,
            style: TextStyle(color: color, fontSize: 12, height: 1.35),
          ),
        ),
        if (!ok)
          TextButton(
            onPressed: onFix,
            child: Text(fixLabel, style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
