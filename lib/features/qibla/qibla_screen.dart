import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/brand_colors.dart';
import '../../data/services/qibla_service.dart';
import '../../shared/widgets/app_background.dart';
import '../../state/theme_controller.dart';
import 'widgets/compass_dial.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with WidgetsBindingObserver {
  late final QiblaService _service;
  bool _granted = false;
  bool _loading = true;
  bool _locationFailed = false;
  Stream<QiblaReading>? _readings;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = context.read<QiblaService>();
    _prepare();
  }

  Future<void> _prepare() async {
    final generation = ++_generation;
    try {
      final granted = await _service.ensurePermission();
      if (granted) await _service.resolveLocation();
      if (!mounted || generation != _generation) return;
      setState(() {
        _granted = granted;
        _locationFailed = false;
        _loading = false;
        _readings = granted
            ? _service.readings().timeout(const Duration(seconds: 10))
            : null;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _locationFailed = true;
        _loading = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      if (!_loading) {
        setState(() => _loading = true);
        unawaited(_prepare());
      }
    } else {
      setState(() => _readings = null);
    }
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
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
                    : (_granted && !_locationFailed
                          ? _content(l10n)
                          : _permission(l10n)),
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
          stream: _readings,
          builder: (context, snapshot) {
            if (snapshot.hasError || !_service.hasCompass) {
              return Text(
                l10n.qiblaCompassUnavailable,
                textAlign: TextAlign.center,
              );
            }
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
            _locationFailed ? l10n.qiblaLocationFailed : l10n.qiblaPermission,
            textAlign: TextAlign.center,
            style: TextStyle(color: BrandColors.textSecondary),
          ),
          TextButton(
            onPressed: openAppSettings,
            child: Text(l10n.openSystemSettings),
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
            child: Text(_locationFailed ? l10n.retryAction : l10n.grantAccess),
          ),
        ],
      ),
    );
  }
}
