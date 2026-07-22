import 'package:flutter/material.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../data/models/mp3quran.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_header.dart';
import 'widgets/radio_list.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  Future<List<QuranRadio>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= loadRadios(context);
  }

  Future<void> _refresh() async {
    final future = loadRadios(context);
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBackground(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            AppHeader.root(title: l10n.radios),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  l10n.radioLive,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: RadioList(
                future: _future!,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                onRefresh: _refresh,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
