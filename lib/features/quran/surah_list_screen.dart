import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand_colors.dart';
import '../../data/models/content.dart';
import '../../data/models/mp3quran.dart';
import '../../data/services/mp3quran_service.dart';
import '../../data/services/quran_service.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_header.dart';
import '../../state/quran_player_controller.dart';
import '../../state/theme_controller.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  Future<List<Surah>>? _future;
  String? _locale;
  bool _restoreAttempted = false;
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Surah> _filter(List<Surah> surahs) {
    if (_search.isEmpty) return surahs;
    final query = _search.toLowerCase();
    return surahs.where((surah) {
      return surah.number.toString() == query ||
          surah.nameLatin.toLowerCase().contains(query) ||
          surah.meaning.toLowerCase().contains(query) ||
          surah.nameArabic.contains(_search);
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_locale != locale) {
      _locale = locale;
      _future = context.read<QuranService>().surahs(locale: locale);
    }
    if (!_restoreAttempted) {
      _restoreAttempted = true;
      _restoreReciter(locale);
    }
  }

  Future<void> _restoreReciter(String locale) async {
    final controller = context.read<QuranPlayerController>();
    if (controller.reciter != null) return;
    final reciterId = controller.restoredReciterId;
    final moshafId = controller.restoredMoshafId;
    if (reciterId == null || moshafId == null) return;
    final service = context.read<Mp3QuranService>();
    try {
      final results = await Future.wait([
        service.reciters(language: locale),
        service.suwar(language: locale),
      ]);
      final reciters = results[0] as List<Reciter>;
      final suwar = results[1] as List<MoshafSurah>;
      final reciter = reciters.firstWhere(
        (item) => item.id == reciterId,
        orElse: () => reciters.isNotEmpty
            ? reciters.first
            : const Reciter(id: 0, name: '', moshaf: []),
      );
      if (reciter.id == 0) return;
      final moshaf = reciter.moshaf.firstWhere(
        (item) => item.id == moshafId,
        orElse: () => reciter.moshaf.first,
      );
      if (!mounted) return;
      controller.setReciter(reciter, moshaf, suwar);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    final future = context.read<QuranService>().surahs(locale: _locale);
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  void _openReciters() {
    context.push('/quran/reciters');
  }

  void _play(int number) {
    final controller = context.read<QuranPlayerController>();
    if (controller.reciter == null) {
      _openReciters();
      return;
    }
    controller.playSurah(number);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final (reciter, moshaf, currentSurahId) = context
        .select<QuranPlayerController, (Reciter?, Moshaf?, int?)>(
          (c) => (c.reciter, c.moshaf, c.currentSurah?.id),
        );
    return AppBackground(
      child: SafeArea(
        child: FutureBuilder<List<Surah>>(
          future: _future,
          builder: (context, snapshot) {
            final surahs = _filter(snapshot.data ?? []);
            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  AppHeader.root(title: l10n.quranReader),
                  SliverToBoxAdapter(
                    child: _ReciterBar(reciter: reciter, onTap: _openReciters),
                  ),
                  SliverToBoxAdapter(
                    child: _SearchField(
                      controller: _searchController,
                      hint: l10n.searchSurah,
                      onChanged: (value) =>
                          setState(() => _search = value.trim()),
                    ),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          l10n.quranUnavailable,
                          style: TextStyle(color: BrandColors.textMuted),
                        ),
                      ),
                    )
                  else if (surahs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          l10n.noResults,
                          style: TextStyle(color: BrandColors.textMuted),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                      sliver: SliverList.separated(
                        itemCount: surahs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final surah = surahs[i];
                          final available =
                              moshaf == null || moshaf.hasSurah(surah.number);
                          return _SurahTile(
                            surah: surah,
                            available: available,
                            isCurrent: currentSurahId == surah.number,
                            onTap: () => context.go('/quran/${surah.number}'),
                            onPlay: available
                                ? () => _play(surah.number)
                                : null,
                          );
                        },
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(Icons.search, color: BrandColors.textMuted),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, color: BrandColors.textMuted),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          hintText: hint,
          hintStyle: TextStyle(color: BrandColors.textMuted, fontSize: 14),
          filled: true,
          fillColor: BrandColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: BrandColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: BrandColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: BrandColors.primary, width: 1.3),
          ),
        ),
      ),
    );
  }
}

class _ReciterBar extends StatelessWidget {
  const _ReciterBar({required this.reciter, required this.onTap});

  final Reciter? reciter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BrandColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BrandColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.record_voice_over, color: BrandColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.reciter,
                        style: TextStyle(
                          color: BrandColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        reciter?.name ?? l10n.selectReciter,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: BrandColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.changeReciter,
                  style: TextStyle(
                    color: BrandColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.chevron_right, color: BrandColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({
    required this.surah,
    required this.available,
    required this.isCurrent,
    required this.onTap,
    required this.onPlay,
  });

  final Surah surah;
  final bool available;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Opacity(
          opacity: available ? 1 : 0.45,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCurrent ? BrandColors.accentSoft : BrandColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent ? BrandColors.accent : BrandColors.border,
              ),
            ),
            child: Row(
              children: [
                _StarBadge(number: surah.number),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.nameLatin,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: BrandColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${surah.meaning} · ${l10n.verses(surah.versesCount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: BrandColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  surah.nameArabic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.arabicQuran(
                    size: 22,
                    color: BrandColors.accent,
                  ),
                ),
                if (onPlay != null) ...[
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    onPressed: onPlay,
                    icon: Icon(isCurrent ? Icons.graphic_eq : Icons.play_arrow),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarBadge extends StatelessWidget {
  const _StarBadge({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BrandColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BrandColors.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: BrandColors.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
