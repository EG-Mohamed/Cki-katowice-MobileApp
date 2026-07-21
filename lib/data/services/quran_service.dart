import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/content.dart';

abstract class QuranService {
  Future<List<Surah>> surahs({String? locale});
  Future<Surah> surah(int number, {String? locale});
}

class ApiQuranService implements QuranService {
  ApiQuranService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://api.alquran.cloud/v1';

  final http.Client _client;

  @override
  Future<List<Surah>> surahs({String? locale}) async {
    final data = await _get('/surah');
    return ((data['data'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_surahSummaryFromJson)
        .toList();
  }

  @override
  Future<Surah> surah(int number, {String? locale}) async {
    final translation = _translationEdition(locale);
    final data = await _get(
      '/surah/$number/editions/quran-uthmani,$translation,ar.alafasy',
    );
    final editions = ((data['data'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .toList();
    final quran = editions.first;
    final translated = editions.length > 1 ? editions[1] : quran;
    final audio = editions.length > 2 ? editions[2] : quran;
    final arabicAyahs = (quran['ayahs'] as List).cast<Map<String, dynamic>>();
    final translatedAyahs = (translated['ayahs'] as List)
        .cast<Map<String, dynamic>>();
    final audioAyahs = (audio['ayahs'] as List?)?.cast<Map<String, dynamic>>();
    return Surah(
      number: quran['number'] as int,
      nameArabic: quran['name'] as String? ?? '',
      nameLatin: quran['englishName'] as String? ?? '',
      meaning: quran['englishNameTranslation'] as String? ?? '',
      versesCount: quran['numberOfAyahs'] as int? ?? arabicAyahs.length,
      revelation: quran['revelationType'] as String? ?? '',
      ayat: [
        for (var i = 0; i < arabicAyahs.length; i++)
          Ayah(
            number: arabicAyahs[i]['numberInSurah'] as int,
            arabic: (arabicAyahs[i]['text'] as String? ?? '').replaceAll(
              '\u{FEFF}',
              '',
            ),
            translation: translatedAyahs.length > i
                ? translatedAyahs[i]['text'] as String? ?? ''
                : '',
            audioUrl: audioAyahs != null && audioAyahs.length > i
                ? audioAyahs[i]['audio'] as String?
                : null,
          ),
      ],
    );
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw QuranApiException(response.statusCode);
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Surah _surahSummaryFromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] as int,
      nameArabic: json['name'] as String? ?? '',
      nameLatin: json['englishName'] as String? ?? '',
      meaning: json['englishNameTranslation'] as String? ?? '',
      versesCount: json['numberOfAyahs'] as int? ?? 0,
      revelation: json['revelationType'] as String? ?? '',
    );
  }

  String _translationEdition(String? locale) {
    switch (locale) {
      case 'pl':
        return 'pl.bielawskiego';
      case 'ar':
        return 'ar.muyassar';
      default:
        return 'en.sahih';
    }
  }
}

class QuranApiException implements Exception {
  const QuranApiException(this.statusCode);

  final int statusCode;
}
