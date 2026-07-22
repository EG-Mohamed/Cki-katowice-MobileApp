import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/brand_colors.dart';
import '../../data/services/qibla_service.dart';
import '../../shared/widgets/app_background.dart';
import 'widgets/compass_dial.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  late final QiblaService _service;
  bool _granted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = context.read<QiblaService>();
    _prepare();
  }

  Future<void> _prepare() async {
    final granted = await _service.ensurePermission();
    if (granted) {
      await _service.resolveLocation();
    }
    if (mounted) {
      setState(() {
        _granted = granted;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: BackButton(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_granted ? _content(l10n) : _permission(l10n)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.qiblaHeading,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.qiblaInstruction,
          textAlign: TextAlign.center,
          style: TextStyle(color: BrandColors.textSecondary, fontSize: 13),
        ),
        const Spacer(),
        StreamBuilder<QiblaReading>(
          stream: _service.readings(),
          builder: (context, snapshot) {
            final reading = snapshot.data;
            return RepaintBoundary(
              child: CompassDial(
                reading: reading,
                alignedLabel: l10n.qiblaAligned,
              ),
            );
          },
        ),
        const Spacer(),
        if (_service.distanceKm != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: BrandColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BrandColors.border),
            ),
            child: Text(
              l10n.qiblaDistance(_service.distanceKm!.toStringAsFixed(0)),
              style: TextStyle(
                color: BrandColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          l10n.calibrateHint,
          textAlign: TextAlign.center,
          style: TextStyle(color: BrandColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _permission(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.explore_off_outlined,
            size: 64,
            color: BrandColors.textMuted,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.qiblaPermission,
            textAlign: TextAlign.center,
            style: TextStyle(color: BrandColors.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: BrandColors.accent,
              foregroundColor: BrandColors.onAccent,
            ),
            onPressed: () {
              setState(() => _loading = true);
              _prepare();
            },
            child: Text(l10n.grantAccess),
          ),
        ],
      ),
    );
  }
}
