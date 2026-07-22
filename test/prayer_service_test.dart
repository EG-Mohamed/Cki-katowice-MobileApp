import 'dart:convert';

import 'package:ckikatowice/data/api/api_client.dart';
import 'package:ckikatowice/data/services/prayer_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('range requests and parses the prayer-times endpoint', () async {
    late Uri requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response(
        jsonEncode({
          'data': [
            {
              'date': '2026-07-21',
              'fajr': {'adhan': '03:29:00'},
              'sunrise': '04:56:00',
              'dhuhr': {'adhan': '12:51:00'},
              'asr': {'adhan': '17:05:00'},
              'maghrib': {'adhan': '20:44:00'},
              'isha': {'adhan': '22:09:00'},
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = ApiPrayerService(ApiClient(client: client));

    final result = await service.range(
      from: DateTime(2026, 7, 21),
      to: DateTime(2026, 7, 23),
    );

    expect(requested.path, '/api/prayer-times');
    expect(requested.queryParameters['from'], '2026-07-21');
    expect(requested.queryParameters['to'], '2026-07-23');
    expect(requested.queryParameters['per_page'], '3');
    expect(result.single.date, DateTime(2026, 7, 21));
    expect(result.single.notifiable.length, 5);
  });
}
