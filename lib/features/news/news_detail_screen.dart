import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand_colors.dart';
import '../../data/models/content.dart';
import '../../data/services/news_service.dart';
import '../../shared/widgets/app_background.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  Future<NewsItem>? _future;
  String? _localeCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_localeCode != locale) {
      _localeCode = locale;
      _future = context.read<NewsService>().find(widget.slug);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return AppBackground(
      child: SafeArea(
        child: FutureBuilder<NewsItem>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  l10n.emptyNews,
                  style: TextStyle(color: BrandColors.textMuted),
                ),
              );
            }
            final item = snapshot.data!;
            final date = DateFormat.yMMMMEEEEd(locale).format(item.date);
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  leading: const BackButton(),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.featuredImageUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.network(
                              item.featuredImageUrl!,
                              height: 210,
                              width: double.infinity,
                              cacheWidth: 1024,
                              cacheHeight: 630,
                              fit: BoxFit.cover,
                              headers: const {
                                'Accept': 'image/*',
                                'User-Agent': 'CKI-Katowice-App',
                              },
                              errorBuilder: (_, _, _) => Container(
                                height: 210,
                                width: double.infinity,
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
                          ),
                          const SizedBox(height: 18),
                        ],
                        if (item.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: BrandColors.accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.category!,
                              style: TextStyle(
                                color: BrandColors.accent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        Text(
                          item.title,
                          style: AppTheme.display(context, size: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          date,
                          style: TextStyle(
                            color: BrandColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          item.body,
                          style: TextStyle(
                            color: BrandColors.textSecondary,
                            fontSize: 15,
                            height: 1.7,
                          ),
                        ),
                      ],
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
}
