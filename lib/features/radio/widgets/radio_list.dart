import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/arb/app_localizations.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../data/models/mp3quran.dart';
import '../../../data/services/mp3quran_service.dart';
import '../../../state/quran_player_controller.dart';
import '../../../state/theme_controller.dart';

const List<QuranRadio> customRadios = [
  QuranRadio(
    id: -1,
    name: 'إذاعة القرآن - القاهرة',
    url: 'https://quran.yousefheiba.com/api/radio',
  ),
];

Future<List<QuranRadio>> loadRadios(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  return context
      .read<Mp3QuranService>()
      .radios(language: locale)
      .then<List<QuranRadio>>((radios) => [...customRadios, ...radios])
      .catchError((_) => customRadios);
}

class RadioList extends StatefulWidget {
  const RadioList({
    super.key,
    required this.future,
    this.scrollController,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 24),
    this.onPlay,
  });

  final Future<List<QuranRadio>> future;
  final ScrollController? scrollController;
  final EdgeInsets padding;
  final VoidCallback? onPlay;

  @override
  State<RadioList> createState() => _RadioListState();
}

class _RadioListState extends State<RadioList> {
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
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final (isRadio, radioName, isPlaying) = context
        .select<QuranPlayerController, (bool, String?, bool)>(
          (c) => (c.isRadio, c.radioName, c.isPlaying),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                controller: widget.scrollController,
                padding: widget.padding,
                itemCount: radios.length,
                separatorBuilder: (_, _) =>
                    Divider(color: BrandColors.border, height: 12),
                itemBuilder: (context, i) {
                  final radio = radios[i];
                  final active = isRadio && radioName == radio.name;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.radio,
                      color: active ? BrandColors.primary : BrandColors.accent,
                    ),
                    title: Text(
                      radio.name,
                      style: TextStyle(
                        color: BrandColors.textPrimary,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    trailing: Icon(
                      active && isPlaying ? Icons.graphic_eq : Icons.play_arrow,
                      color: BrandColors.primary,
                    ),
                    onTap: () {
                      context.read<QuranPlayerController>().playRadio(
                        radio.name,
                        radio.url,
                      );
                      widget.onPlay?.call();
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
