import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand_colors.dart';
import '../../data/models/content.dart';
import '../../data/services/khutba_service.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/geometric_pattern.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/theme_controller.dart';

class KhutbaListScreen extends StatefulWidget {
  const KhutbaListScreen({super.key});

  @override
  State<KhutbaListScreen> createState() => _KhutbaListScreenState();
}

class _KhutbaListScreenState extends State<KhutbaListScreen> {
  Future<List<Khutba>>? _future;
  String? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_locale != locale) {
      _locale = locale;
      _future = context.read<KhutbaService>().all();
    }
  }

  Future<void> _refresh() async {
    final future = context.read<KhutbaService>().all();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    return AppBackground(
      child: SafeArea(
        child: FutureBuilder<List<Khutba>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(
                      height: 420,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 420,
                      child: Center(
                        child: Text(
                          l10n.emptyKhutba,
                          style: TextStyle(color: BrandColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            final all = snapshot.data!;
            final upcoming = all.where((k) => k.isUpcoming).toList();
            final past = all.where((k) => !k.isUpcoming).toList();
            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  AppHeader.detail(title: l10n.khutbaTitle),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (all.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 120),
                            child: Center(
                              child: Text(
                                l10n.emptyKhutba,
                                style: TextStyle(color: BrandColors.textMuted),
                              ),
                            ),
                          ),
                        if (upcoming.isNotEmpty) ...[
                          SectionHeader(title: l10n.upcoming),
                          const SizedBox(height: 12),
                          _FeaturedKhutba(
                            khutba: upcoming.first,
                            onTap: () => context.go(
                              '/khutba/${Uri.encodeComponent(upcoming.first.slug)}',
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (past.isNotEmpty) ...[
                          SectionHeader(title: l10n.past),
                          const SizedBox(height: 12),
                          for (final k in past) ...[
                            _KhutbaTile(
                              khutba: k,
                              onTap: () => context.go(
                                '/khutba/${Uri.encodeComponent(k.slug)}',
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeaturedKhutba extends StatelessWidget {
  const _FeaturedKhutba({required this.khutba, required this.onTap});
  final Khutba khutba;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMMEEEEd(locale).format(khutba.date);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BrandColors.primaryLight,
                        BrandColors.primaryDark,
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: GeometricPattern(
                  color: BrandColors.accent,
                  opacity: 0.10,
                  cell: 52,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.record_voice_over,
                      color: BrandColors.accent,
                      size: 26,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      khutba.title,
                      style: AppTheme.display(context, size: 26),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      khutba.summary,
                      style: TextStyle(
                        color: BrandColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$date · ${l10n.khatib(khutba.khatib)}',
                      style: TextStyle(color: BrandColors.accent, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KhutbaTile extends StatelessWidget {
  const _KhutbaTile({required this.khutba, required this.onTap});
  final Khutba khutba;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMd(locale).format(khutba.date);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BrandColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BrandColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      khutba.title,
                      style: TextStyle(
                        color: BrandColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$date · ${khutba.khatib}',
                      style: TextStyle(
                        color: BrandColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: BrandColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
