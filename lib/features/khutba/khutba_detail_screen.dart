import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand_colors.dart';
import '../../data/models/content.dart';
import '../../data/services/khutba_service.dart';
import '../../shared/widgets/app_background.dart';

class KhutbaDetailScreen extends StatefulWidget {
  const KhutbaDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  State<KhutbaDetailScreen> createState() => _KhutbaDetailScreenState();
}

class _KhutbaDetailScreenState extends State<KhutbaDetailScreen> {
  Future<Khutba>? _future;
  String? _localeCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_localeCode != locale) {
      _localeCode = locale;
      _future = context.read<KhutbaService>().find(widget.slug);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return AppBackground(
      child: SafeArea(
        child: FutureBuilder<Khutba>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  l10n.emptyKhutba,
                  style: TextStyle(color: BrandColors.textMuted),
                ),
              );
            }
            final k = snapshot.data!;
            final date = DateFormat.yMMMMEEEEd(locale).format(k.date);
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
                        Icon(
                          Icons.record_voice_over,
                          color: BrandColors.accent,
                          size: 30,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          k.title,
                          style: AppTheme.display(context, size: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.khatib(k.khatib),
                          style: TextStyle(
                            color: BrandColors.accent,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            color: BrandColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          k.body,
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
