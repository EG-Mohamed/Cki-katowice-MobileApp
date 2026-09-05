import 'dart:convert';

import 'package:ckikatowice/data/api/api_client.dart';
import 'package:ckikatowice/data/services/prayer_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
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

  test(
    'concurrent range requests share one network request and complete',
    () async {
      var calls = 0;
      final service = ApiPrayerService(
        ApiClient(
          client: MockClient((_) async {
            calls++;
            return http.Response(
              jsonEncode({
                'data': [_raw('2026-09-05')],
              }),
              200,
            );
          }),
        ),
      );
      final result = await Future.wait([
        service.range(from: DateTime(2026, 9, 5), to: DateTime(2026, 9, 5)),
        service.range(from: DateTime(2026, 9, 5), to: DateTime(2026, 9, 5)),
      ]);
      expect(calls, 1);
      expect(result.every((days) => days.length == 1), true);
    },
  );

  test(
    'new service instance reads offline cache after single-day fetch',
    () async {
      final date = DateTime.now();
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final first = ApiPrayerService(
        ApiClient(
          client: MockClient(
            (_) async =>
                http.Response(jsonEncode({'data': _raw(dateString)}), 200),
          ),
        ),
      );
      await first.forDate(date);
      final offline = ApiPrayerService(
        ApiClient(
          client: MockClient(
            (_) async => throw const FormatException('offline'),
          ),
        ),
      );
      final restored = await offline.forDate(date);
      expect(restored.slots.first.time.hour, 5);
    },
  );

  test('Friday with null Jumuah time falls back to Dhuhr', () async {
    final service = ApiPrayerService(
      ApiClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': [
                {
                  ..._raw('2026-09-11'),
                  'jummah': {'adhan': null, 'iqamah': null},
                },
              ],
            }),
            200,
          ),
        ),
      ),
    );
    final result = await service.range(
      from: DateTime(2026, 9, 11),
      to: DateTime(2026, 9, 11),
    );
    expect(result.single.notifiable.length, 5);
    expect(result.single.notifiable[1].name.name, 'dhuhr');
  });

  test('malformed date does not discard healthy range entries', () async {
    final service = ApiPrayerService(
      ApiClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': [
                _raw('2026-09-05'),
                {
                  ..._raw('2026-09-06'),
                  'fajr': {'adhan': '29:90'},
                },
              ],
            }),
            200,
          ),
        ),
      ),
    );
    final result = await service.range(
      from: DateTime(2026, 9, 5),
      to: DateTime(2026, 9, 6),
    );
    expect(result.length, 1);
    expect(result.single.date, DateTime(2026, 9, 5));
  });
}

Map<String, Object?> _raw(String date) => {
  'date': date,
  'fajr': {'adhan': '05:00'},
  'sunrise': '06:30',
  'dhuhr': {'adhan': '12:00'},
  'asr': {'adhan': '16:00'},
  'maghrib': {'adhan': '19:00'},
  'isha': {'adhan': '21:00'},
};
