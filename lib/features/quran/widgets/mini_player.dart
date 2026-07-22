import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../data/models/mp3quran.dart';
import '../../../shared/shell_scope.dart';
import '../../../state/quran_player_controller.dart';
import '../../../state/theme_controller.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    super.key,
    required this.onOpenSurah,
    required this.onOpenRadio,
  });

  final ValueChanged<int> onOpenSurah;
  final VoidCallback onOpenRadio;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final controller = context.watch<QuranPlayerController>();
    if (!controller.hasTrack) return const SizedBox.shrink();

    final surah = controller.currentSurah;
    final isRadio = controller.isRadio;
    final title = isRadio ? (controller.radioName ?? '') : (surah?.name ?? '');
    final subtitle = isRadio ? '' : (controller.reciter?.name ?? '');

    return ValueListenableBuilder<String>(
      valueListenable: ShellScope.location,
      builder: (context, location, _) {
        if (location == '/now-playing') {
          return const SizedBox.shrink();
        }
        if (!isRadio && surah != null && location == '/quran/${surah.id}') {
          return const SizedBox.shrink();
        }
        return _bar(context, controller, surah, isRadio, title, subtitle);
      },
    );
  }

  Widget _bar(
    BuildContext context,
    QuranPlayerController controller,
    MoshafSurah? surah,
    bool isRadio,
    String title,
    String subtitle,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable: ShellScope.isShellRoute,
      builder: (context, isShell, child) {
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final offset = isShell
            ? ShellScope.bottomNavHeight + bottomInset + 8
            : bottomInset + 8;
        return Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, offset),
          child: child,
        );
      },
      child: Material(
        color: BrandColors.surface,
        elevation: 6,
        shadowColor: BrandColors.textPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (isRadio || surah == null) {
              onOpenRadio();
            } else {
              onOpenSurah(surah.id);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: ValueListenableBuilder<PlaybackProgress>(
                  valueListenable: controller.progress,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value.value,
                    minHeight: 2.5,
                    backgroundColor: BrandColors.surfaceMuted,
                    color: BrandColors.accent,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: BrandColors.accentSoft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        isRadio ? Icons.radio : Icons.graphic_eq,
                        color: BrandColors.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: isRadio
                                ? TextStyle(
                                    color: BrandColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  )
                                : AppTheme.arabicQuran(
                                    size: 16,
                                    color: BrandColors.textPrimary,
                                  ).copyWith(height: 1.2),
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: BrandColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isRadio)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: controller.hasPrevious
                            ? controller.previous
                            : null,
                        icon: const Icon(Icons.skip_previous),
                        color: BrandColors.textSecondary,
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: BrandColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: controller.togglePlayPause,
                        icon: Icon(
                          controller.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        color: BrandColors.onPrimary,
                      ),
                    ),
                    if (!isRadio)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: controller.hasNext ? controller.next : null,
                        icon: const Icon(Icons.skip_next),
                        color: BrandColors.textSecondary,
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: controller.stop,
                      icon: const Icon(Icons.close),
                      color: BrandColors.textMuted,
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
