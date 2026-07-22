import 'package:flutter/material.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/mp3quran.dart';
import '../../shared/widgets/app_background.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                l10n.radios,
                style: AppTheme.display(context, size: 30),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                l10n.radioLive,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: RadioList(
                future: _future!,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
