import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/brand_colors.dart';
import '../../data/models/mp3quran.dart';
import '../../data/services/mp3quran_service.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_header.dart';
import '../../state/quran_player_controller.dart';
import '../../state/theme_controller.dart';

class ReciterPickerScreen extends StatefulWidget {
  const ReciterPickerScreen({super.key});

  @override
  State<ReciterPickerScreen> createState() => _ReciterPickerScreenState();
}

class _ReciterPickerScreenState extends State<ReciterPickerScreen> {
  Future<_ReciterData>? _future;
  String? _locale;
  int? _riwayahFilter;
  String _search = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_locale != locale) {
      _locale = locale;
      _future = _load(locale);
    }
  }

  Future<_ReciterData> _load(String? locale) async {
    final service = context.read<Mp3QuranService>();
    final results = await Future.wait([
      service.reciters(language: locale),
      service.riwayat(language: locale),
      service.suwar(language: locale),
    ]);
    return _ReciterData(
      reciters: results[0] as List<Reciter>,
      riwayat: results[1] as List<Riwayah>,
      suwar: results[2] as List<MoshafSurah>,
    );
  }

  Future<void> _select(
    Reciter reciter,
    Moshaf moshaf,
    List<MoshafSurah> suwar,
  ) async {
    context.read<QuranPlayerController>().setReciter(reciter, moshaf, suwar);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    return AppBackground(
      child: SafeArea(
        child: FutureBuilder<_ReciterData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return CustomScrollView(
                slivers: [
                  AppHeader.detail(title: l10n.selectReciter),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        l10n.recitersUnavailable,
                        style: TextStyle(color: BrandColors.textMuted),
                      ),
                    ),
                  ),
                ],
              );
            }
            final data = snapshot.data!;
            final reciters = _filter(data.reciters);
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                AppHeader.detail(title: l10n.selectReciter),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.searchReciters,
                        filled: true,
                        fillColor: BrandColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: BrandColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: BrandColors.border),
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _search = value.trim().toLowerCase()),
                    ),
                  ),
                ),
                if (data.riwayat.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _RiwayahChip(
                            label: l10n.allCategories,
                            selected: _riwayahFilter == null,
                            onTap: () => setState(() => _riwayahFilter = null),
                          ),
                          for (final riwayah in data.riwayat)
                            _RiwayahChip(
                              label: riwayah.name,
                              selected: _riwayahFilter == riwayah.id,
                              onTap: () =>
                                  setState(() => _riwayahFilter = riwayah.id),
                            ),
                        ],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  sliver: SliverList.separated(
                    itemCount: reciters.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _ReciterTile(
                      reciter: reciters[i],
                      riwayahFilter: _riwayahFilter,
                      onSelect: (moshaf) =>
                          _select(reciters[i], moshaf, data.suwar),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Reciter> _filter(List<Reciter> reciters) {
    return reciters.where((reciter) {
      final matchesSearch =
          _search.isEmpty || reciter.name.toLowerCase().contains(_search);
      final matchesRiwayah =
          _riwayahFilter == null ||
          reciter.moshaf.any((moshaf) => moshaf.moshafType == _riwayahFilter);
      return matchesSearch && matchesRiwayah;
    }).toList();
  }
}

class _ReciterData {
  const _ReciterData({
    required this.reciters,
    required this.riwayat,
    required this.suwar,
  });

  final List<Reciter> reciters;
  final List<Riwayah> riwayat;
  final List<MoshafSurah> suwar;
}

class _RiwayahChip extends StatelessWidget {
  const _RiwayahChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: BrandColors.primarySoft,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: selected ? BrandColors.primary : BrandColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 12,
        ),
        backgroundColor: BrandColors.surface,
        side: BorderSide(color: BrandColors.border),
      ),
    );
  }
}

class _ReciterTile extends StatelessWidget {
  const _ReciterTile({
    required this.reciter,
    required this.riwayahFilter,
    required this.onSelect,
  });

  final Reciter reciter;
  final int? riwayahFilter;
  final ValueChanged<Moshaf> onSelect;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final moshaf = reciter.moshaf
        .where((m) => riwayahFilter == null || m.moshafType == riwayahFilter)
        .toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reciter.name,
            style: TextStyle(
              color: BrandColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in moshaf)
                ActionChip(
                  avatar: Icon(
                    Icons.play_arrow,
                    size: 16,
                    color: BrandColors.primary,
                  ),
                  label: Text('${m.name} · ${m.surahTotal}'),
                  onPressed: () => onSelect(m),
                  labelStyle: TextStyle(
                    color: BrandColors.textSecondary,
                    fontSize: 12,
                  ),
                  backgroundColor: BrandColors.surfaceMuted,
                  side: BorderSide(color: BrandColors.border),
                ),
            ],
          ),
          if (moshaf.isEmpty)
            Text(
              l10n.noReciterSelected,
              style: TextStyle(color: BrandColors.textMuted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
