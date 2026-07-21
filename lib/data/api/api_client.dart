import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? client, this.locale = 'en'})
    : _client = client ?? http.Client();

  static const String baseUrl = 'https://ckikatowice.pl/api';

  final http.Client _client;
  String locale;

  Future<dynamic> get(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    final decoded = await getEnvelope(path, query: query);
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  Future<dynamic> getEnvelope(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: _queryParameters(query));
    final response = await _client
        .get(uri, headers: {
          'Accept': 'application/json',
          'Accept-locale': locale,
        })
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode);
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Map<String, String>? _queryParameters(Map<String, Object?> query) {
    final values = <String, String>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value != null) {
        values[entry.key] = value.toString();
      }
    }
    return values.isEmpty ? null : values;
  }
}

class ApiException implements Exception {
  const ApiException(this.statusCode);

  final int statusCode;
}
