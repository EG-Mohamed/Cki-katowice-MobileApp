import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand_colors.dart';
import '../../data/models/mp3quran.dart';
import '../../shared/widgets/geometric_pattern.dart';
import '../../state/quran_player_controller.dart';
import '../../state/theme_controller.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<QuranPlayerController>();
    final surah = controller.currentSurah;
    final reciter = controller.reciter;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.hero),
          ),
        ),
        const Positioned.fill(
          child: GeometricPattern(color: Colors.white, opacity: 0.06),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      color: Colors.white,
                    ),
                    const Spacer(),
                    Text(
                      l10n.nowPlaying,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: surah == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book,
                              color: Colors.white,
                              size: 64,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.noReciterSelected,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _ArtworkIcon(),
                          const SizedBox(height: 28),
                          Text(
                            surah.name,
                            textAlign: TextAlign.center,
                            style: AppTheme.arabicQuran(
                              size: 34,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            reciter?.name ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
              const _ProgressBar(),
              const _Controls(),
              _BottomActions(l10n: l10n),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArtworkIcon extends StatelessWidget {
  const _ArtworkIcon();

  @override
  Widget build(BuildContext context) {
    final isPlaying = context.select<QuranPlayerController, bool>(
      (c) => c.isPlaying,
    );
    return Container(
      width: 150,
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Icon(
        isPlaying ? Icons.graphic_eq : Icons.menu_book,
        color: Colors.white,
        size: 56,
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<QuranPlayerController>();
    return ValueListenableBuilder<PlaybackProgress>(
      valueListenable: controller.progress,
      builder: (context, progress, _) => _build(context, controller, progress),
    );
  }

  Widget _build(
    BuildContext context,
    QuranPlayerController controller,
    PlaybackProgress progress,
  ) {
    final duration = progress.duration;
    final position = progress.position;
    final maxMs = duration.inMilliseconds.toDouble();
    final value = position.inMilliseconds
        .clamp(0, duration.inMilliseconds)
        .toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
              thumbColor: Colors.white,
              trackHeight: 3,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: maxMs <= 0 ? 0 : value,
              max: maxMs <= 0 ? 1 : maxMs,
              onChanged: maxMs <= 0
                  ? null
                  : (v) => controller.seek(Duration(milliseconds: v.round())),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _format(position),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  _format(duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _Controls extends StatelessWidget {
  const _Controls();

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final controller = context.read<QuranPlayerController>();
    final isPlaying = context.select<QuranPlayerController, bool>(
      (c) => c.isPlaying,
    );
    final hasPrevious = context.select<QuranPlayerController, bool>(
      (c) => c.hasPrevious,
    );
    final hasNext = context.select<QuranPlayerController, bool>(
      (c) => c.hasNext,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            iconSize: 40,
            onPressed: hasPrevious ? controller.previous : null,
            icon: const Icon(Icons.skip_previous),
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              iconSize: 44,
              onPressed: controller.togglePlayPause,
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              color: BrandColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            iconSize: 40,
            onPressed: hasNext ? controller.next : null,
            icon: const Icon(Icons.skip_next),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<QuranPlayerController>();
    final surah = context.select<QuranPlayerController, MoshafSurah?>(
      (c) => c.currentSurah,
    );
    final autoplayNext = context.select<QuranPlayerController, bool>(
      (c) => c.autoplayNext,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Switch(
                value: autoplayNext,
                onChanged: controller.setAutoplayNext,
              ),
              Text(
                l10n.autoplayNext,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          if (surah != null)
            TextButton.icon(
              onPressed: () => context.go('/quran/${surah.id}'),
              icon: const Icon(Icons.menu_book, color: Colors.white),
              label: Text(
                l10n.readText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
