import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand_colors.dart';
import '../../data/models/content.dart';
import '../../data/services/quran_service.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_header.dart';
import '../../state/quran_player_controller.dart';
import '../../state/theme_controller.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.surahNumber});
  final int surahNumber;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<ProcessingState>? _completeSubscription;
  double _fontSize = 26;
  bool _showTranslation = true;
  Future<Surah>? _future;
  Surah? _surah;
  String? _locale;
  int? _playingAyah;

  @override
  void initState() {
    super.initState();
    _completeSubscription = _player.processingStateStream.listen(
      (state) {
        if (!mounted) return;
        if (state == ProcessingState.completed) {
          setState(() => _clearPlaybackState());
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        setState(() => _clearPlaybackState());
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_locale != locale) {
      _locale = locale;
      _future = context.read<QuranService>().surah(
        widget.surahNumber,
        locale: locale,
      );
    }
  }

  Future<void> _toggleAudio(Ayah ayah) async {
    final audioUrl = ayah.audioUrl;
    if (audioUrl == null) return;
    if (_playingAyah == ayah.number) {
      await _player.stop();
      if (!mounted) return;
      setState(() => _clearPlaybackState());
      return;
    }
    await context.read<QuranPlayerController>().stop();
    try {
      await _player.stop();
      await _player.setUrl(audioUrl);
      await _player.play();
      if (!mounted) return;
      setState(() => _playingAyah = ayah.number);
    } catch (_) {
      if (!mounted) return;
      setState(() => _clearPlaybackState());
    }
  }

  Future<void> _toggleSurahAudio() async {
    final surah = _surah;
    if (surah == null) return;
    final controller = context.read<QuranPlayerController>();
    if (controller.reciter == null) {
      context.push('/quran/reciters');
      return;
    }
    await _player.stop();
    if (mounted) setState(() => _clearPlaybackState());
    final isCurrent =
        controller.currentSurah?.id == widget.surahNumber &&
        controller.isPlaying;
    if (isCurrent) {
      await controller.togglePlayPause();
    } else {
      await controller.playSurah(widget.surahNumber);
    }
  }

  void _clearPlaybackState() {
    _playingAyah = null;
  }

  Future<void> _refresh() async {
    final future = context.read<QuranService>().surah(
      widget.surahNumber,
      locale: _locale,
    );
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  void dispose() {
    _completeSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final isPlayingSurah = context.select<QuranPlayerController, bool>(
      (player) =>
          player.currentSurah?.id == widget.surahNumber && player.isPlaying,
    );
    return AppBackground(
      child: SafeArea(
        child: FutureBuilder<Surah>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  l10n.quranUnavailable,
                  style: TextStyle(color: BrandColors.textMuted),
                ),
              );
            }
            final surah = snapshot.data!;
            _surah = surah;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  AppHeader.detail(
                    title: surah.nameLatin,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          surah.nameArabic,
                          style: AppTheme.arabicQuran(
                            size: 20,
                            color: BrandColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Text(
                        surah.meaning,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: BrandColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _Controls(
                      fontSize: _fontSize,
                      showTranslation: _showTranslation,
                      isPlayingSurah: isPlayingSurah,
                      onFont: (v) => setState(() => _fontSize = v),
                      onTranslation: (v) =>
                          setState(() => _showTranslation = v),
                      onSurahAudio: _toggleSurahAudio,
                      translationLabel: l10n.translation,
                      fontLabel: l10n.fontSize,
                      listenLabel: l10n.listenQuran,
                      stopLabel: l10n.stopListening,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    sliver: SliverList.separated(
                      itemCount: surah.ayat.length,
                      separatorBuilder: (_, _) =>
                          Divider(color: BrandColors.border, height: 28),
                      itemBuilder: (context, i) => _AyahView(
                        ayah: surah.ayat[i],
                        fontSize: _fontSize,
                        showTranslation: _showTranslation,
                        isPlaying: _playingAyah == surah.ayat[i].number,
                        onAudio: () => _toggleAudio(surah.ayat[i]),
                      ),
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

class _Controls extends StatelessWidget {
  const _Controls({
    required this.fontSize,
    required this.showTranslation,
    required this.isPlayingSurah,
    required this.onFont,
    required this.onTranslation,
    required this.onSurahAudio,
    required this.translationLabel,
    required this.fontLabel,
    required this.listenLabel,
    required this.stopLabel,
  });

  final double fontSize;
  final bool showTranslation;
  final bool isPlayingSurah;
  final ValueChanged<double> onFont;
  final ValueChanged<bool> onTranslation;
  final VoidCallback onSurahAudio;
  final String translationLabel;
  final String fontLabel;
  final String listenLabel;
  final String stopLabel;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields,
                size: 18,
                color: BrandColors.textSecondary,
              ),
              Expanded(
                child: Slider(
                  value: fontSize,
                  min: 20,
                  max: 38,
                  activeColor: BrandColors.accent,
                  inactiveColor: BrandColors.border,
                  onChanged: onFont,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                translationLabel,
                style: TextStyle(
                  color: BrandColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Switch(value: showTranslation, onChanged: onTranslation),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSurahAudio,
              icon: Icon(isPlayingSurah ? Icons.stop : Icons.play_arrow),
              label: Text(isPlayingSurah ? stopLabel : listenLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahView extends StatelessWidget {
  const _AyahView({
    required this.ayah,
    required this.fontSize,
    required this.showTranslation,
    required this.isPlaying,
    required this.onAudio,
  });

  final Ayah ayah;
  final double fontSize;
  final bool showTranslation;
  final bool isPlaying;
  final VoidCallback onAudio;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, left: 10),
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BrandColors.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${ayah.number}',
                  style: TextStyle(color: BrandColors.accent, fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  ayah.arabic,
                  textAlign: TextAlign.right,
                  style: AppTheme.arabicQuran(size: fontSize),
                ),
              ),
              if (ayah.audioUrl != null) ...[
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: onAudio,
                  icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                ),
              ],
            ],
          ),
        ),
        if (showTranslation) ...[
          const SizedBox(height: 10),
          Text(
            ayah.translation,
            style: TextStyle(
              color: BrandColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
