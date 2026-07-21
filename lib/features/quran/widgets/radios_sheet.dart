import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/arb/app_localizations.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../data/models/mp3quran.dart';
import '../../../data/services/mp3quran_service.dart';
import '../../../state/quran_player_controller.dart';

const List<QuranRadio> _customRadios = [
  QuranRadio(
    id: -1,
    name: 'إذاعة القرآن - القاهرة',
    url: 'https://stream.radiojar.com/8s5u5tpdtwzuv',
  ),
];

Future<void> showRadiosSheet(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  final service = context.read<Mp3QuranService>();
  final future = service
      .radios(language: locale)
      .then<List<QuranRadio>>((radios) => [..._customRadios, ...radios])
      .catchError((_) => _customRadios);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: BrandColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _RadiosSheet(future: future),
  );
}

class _RadiosSheet extends StatefulWidget {
  const _RadiosSheet({required this.future});

  final Future<List<QuranRadio>> future;

  @override
  State<_RadiosSheet> createState() => _RadiosSheetState();
}

class _RadiosSheetState extends State<_RadiosSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QuranRadio> _filter(List<QuranRadio> radios) {
    if (_search.isEmpty) return radios;
    final query = _search.toLowerCase();
    return radios
        .where((radio) => radio.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                l10n.radios,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value.trim()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search, color: BrandColors.textMuted),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close, color: BrandColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        ),
                  hintText: l10n.searchRadios,
                  hintStyle: TextStyle(color: BrandColors.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: BrandColors.surfaceMuted,
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
            ),
            Expanded(
              child: FutureBuilder<List<QuranRadio>>(
                future: widget.future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return Center(
                      child: Text(
                        l10n.recitersUnavailable,
                        style: TextStyle(color: BrandColors.textMuted),
                      ),
                    );
                  }
                  final radios = _filter(snapshot.data!);
                  if (radios.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noResults,
                        style: TextStyle(color: BrandColors.textMuted),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: radios.length,
                    separatorBuilder: (_, _) =>
                        Divider(color: BrandColors.border, height: 12),
                    itemBuilder: (context, i) {
                      final radio = radios[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.radio, color: BrandColors.accent),
                        title: Text(
                          radio.name,
                          style: TextStyle(color: BrandColors.textPrimary),
                        ),
                        trailing: Icon(
                          Icons.play_arrow,
                          color: BrandColors.primary,
                        ),
                        onTap: () {
                          context
                              .read<QuranPlayerController>()
                              .playRadio(radio.name, radio.url);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
