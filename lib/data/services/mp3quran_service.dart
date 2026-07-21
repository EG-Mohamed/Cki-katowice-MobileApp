import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mp3quran.dart';

abstract class Mp3QuranService {
  Future<List<Reciter>> reciters({String? language, int? rewaya, int? sura});
  Future<List<MoshafSurah>> suwar({String? language});
  Future<List<Riwayah>> riwayat({String? language});
  Future<List<QuranRadio>> radios({String? language});
}

class ApiMp3QuranService implements Mp3QuranService {
  ApiMp3QuranService({http.Client? client})
    : _client = client ?? http.Client();

  static const String _baseUrl = 'https://mp3quran.net/api/v3';

  final http.Client _client;

  @override
  Future<List<Reciter>> reciters({
    String? language,
    int? rewaya,
    int? sura,
  }) async {
    final data = await _get('/reciters', query: {
      'language': _lang(language),
      'rewaya': rewaya,
      'sura': sura,
    });
    return ((data['reciters'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(Reciter.fromJson)
        .where((reciter) => reciter.id > 0 && reciter.moshaf.isNotEmpty)
        .toList();
  }

  @override
  Future<List<MoshafSurah>> suwar({String? language}) async {
    final data = await _get('/suwar', query: {'language': _lang(language)});
    return ((data['suwar'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(MoshafSurah.fromJson)
        .where((surah) => surah.id > 0)
        .toList();
  }

  @override
  Future<List<Riwayah>> riwayat({String? language}) async {
    final data = await _get('/riwayat', query: {'language': _lang(language)});
    return ((data['riwayat'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(Riwayah.fromJson)
        .where((riwayah) => riwayah.id > 0)
        .toList();
  }

  @override
  Future<List<QuranRadio>> radios({String? language}) async {
    final data = await _get('/radios', query: {'language': _lang(language)});
    return ((data['radios'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(QuranRadio.fromJson)
        .where((radio) => radio.id > 0 && radio.url.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    final values = <String, String>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value != null && value.toString().isNotEmpty) {
        values[entry.key] = value.toString();
      }
    }
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: values.isEmpty ? null : values);
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Mp3QuranApiException(response.statusCode);
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  static String _lang(String? locale) {
    return locale == 'ar' ? 'ar' : 'eng';
  }
}

class Mp3QuranApiException implements Exception {
  const Mp3QuranApiException(this.statusCode);

  final int statusCode;
}
