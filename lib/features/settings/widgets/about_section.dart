import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/arb/app_localizations.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../data/models/content.dart';
import '../../../state/theme_controller.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({
    super.key,
    required this.settings,
    required this.fallbackName,
    required this.fallbackBody,
  });

  final SiteSettings? settings;
  final String fallbackName;
  final String fallbackBody;

  @override
  Widget build(BuildContext context) {
    final data = settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (data != null && data.logo.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        data.logo,
                        width: 48,
                        height: 48,
                        cacheWidth: 144,
                        cacheHeight: 144,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _LogoFallback(),
                      ),
                    )
                  else
                    _LogoFallback(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data?.name.isNotEmpty == true ? data!.name : fallbackName,
                      style: TextStyle(
                        color: BrandColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data?.description.isNotEmpty == true
                    ? data!.description
                    : fallbackBody,
                style: TextStyle(
                  color: BrandColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              if (data != null && data.url.isNotEmpty) ...[
                const SizedBox(height: 10),
                _LinkRow(
                  icon: Icons.language,
                  label: data.url.replaceFirst(RegExp(r'^https?://'), ''),
                  onTap: () => _open(Uri.parse(data.url)),
                ),
              ],
            ],
          ),
        ),
        if (data != null) ...[
          const SizedBox(height: 12),
          _ContactCard(data: data),
          if (data.social.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SocialRow(social: data.social),
          ],
          if (data.hasLocation) ...[
            const SizedBox(height: 12),
            _LocationCard(data: data),
          ],
        ],
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.data});

  final SiteSettings data;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final rows = <Widget>[];
    if (data.primaryPhone.isNotEmpty) {
      rows.add(
        _LinkRow(
          icon: Icons.call,
          label: data.primaryPhone,
          onTap: () => _open(Uri(scheme: 'tel', path: data.primaryPhone)),
        ),
      );
    }
    if (data.secondaryPhone.isNotEmpty) {
      rows.add(
        _LinkRow(
          icon: Icons.call_outlined,
          label: data.secondaryPhone,
          onTap: () => _open(Uri(scheme: 'tel', path: data.secondaryPhone)),
        ),
      );
    }
    if (data.email.isNotEmpty) {
      rows.add(
        _LinkRow(
          icon: Icons.mail_outline,
          label: data.email,
          onTap: () => _open(Uri(scheme: 'mailto', path: data.email)),
        ),
      );
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return _Card(
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(color: BrandColors.border, height: 20),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.social});

  final Map<String, String> social;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    const icons = {
      'facebook': Icons.facebook,
      'twitter': Icons.alternate_email,
      'instagram': Icons.camera_alt_outlined,
      'youtube': Icons.smart_display_outlined,
    };
    final entries = social.entries.toList();
    return _Card(
      child: Row(
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton.filledTonal(
                onPressed: () => _open(Uri.parse(entry.value)),
                icon: Icon(
                  icons[entry.key] ?? Icons.public,
                  color: BrandColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.data});

  final SiteSettings data;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final lat = data.latitude!;
    final lng = data.longitude!;
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _StaticMap(lat: lat, lng: lng),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.address.isNotEmpty)
                  Text(
                    data.address,
                    style: TextStyle(
                      color: BrandColors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _open(_mapsUri(lat, lng, data.address)),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(l10n.openInMaps),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticMap extends StatelessWidget {
  const _StaticMap({required this.lat, required this.lng});

  final double lat;
  final double lng;

  static const int _zoom = 15;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final n = math.pow(2, _zoom).toDouble();
    final latRad = lat * math.pi / 180;
    final x = ((lng + 180) / 360 * n).floor();
    final y =
        ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
                2 *
                n)
            .floor();
    final url = 'https://tile.openstreetmap.org/$_zoom/$x/$y.png';
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: BrandColors.surfaceMuted),
        Image.network(
          url,
          cacheWidth: 720,
          cacheHeight: 420,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Icon(Icons.place, color: BrandColors.primary, size: 40),
          ),
        ),
        Center(
          child: Icon(
            Icons.location_on,
            color: BrandColors.primary,
            size: 40,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: BrandColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: BrandColors.textPrimary, fontSize: 13),
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: BrandColors.textMuted),
        ],
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BrandColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.mosque, color: BrandColors.primary),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandColors.border),
      ),
      child: child,
    );
  }
}

Uri _mapsUri(double lat, double lng, String address) {
  final query = address.isNotEmpty ? Uri.encodeComponent(address) : '$lat,$lng';
  return Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
}

Future<void> _open(Uri uri) async {
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
