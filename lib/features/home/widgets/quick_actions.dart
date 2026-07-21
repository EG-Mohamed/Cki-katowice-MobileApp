import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/arb/app_localizations.dart';
import '../../../core/theme/brand_colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = [
      _Action(Icons.explore_outlined, l10n.qiblaDirection, '/qibla', true),
      _Action(Icons.menu_book_outlined, l10n.quranReader, '/quran', false),
      _Action(Icons.article_outlined, l10n.newsAnnouncements, '/news', true),
      _Action(
        Icons.record_voice_over_outlined,
        l10n.khutbaTitle,
        '/khutba',
        false,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _ActionCard(action: actions[i])),
          ],
        ],
      ),
    );
  }
}

class _Action {
  const _Action(this.icon, this.label, this.route, this.green);
  final IconData icon;
  final String label;
  final String route;
  final bool green;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});
  final _Action action;

  @override
  Widget build(BuildContext context) {
    final tint = action.green ? BrandColors.primary : BrandColors.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(action.route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: BrandColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BrandColors.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: tint, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: BrandColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
