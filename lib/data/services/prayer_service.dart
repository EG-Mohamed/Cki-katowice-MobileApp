import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/prayer_time.dart';
import '../api/api_client.dart';
import '../models/prayer.dart';

abstract class PrayerService {
  Future<DailyPrayers> today();
  Future<DailyPrayers> forDate(DateTime date);
  Future<List<DailyPrayers>> range({
    required DateTime from,
    required DateTime to,
  });
}

class ApiPrayerService implements PrayerService {
  ApiPrayerService(this._api);
  final ApiClient _api;
  static const _prefix = 'prayer_day_v2_';
  final _memory = <String, ({DailyPrayers day, DateTime fetched})>{};
  final _dailyRequests = <String, Future<DailyPrayers>>{};
  final _rangeRequests = <String, Future<List<DailyPrayers>>>{};

  @override
  Future<DailyPrayers> today() => forDate(prayerToday());

  @override
  Future<DailyPrayers> forDate(DateTime date) {
    date = DateTime(date.year, date.month, date.day);
    final key = _date(date);
    final cached = _memory[key];
    if (cached != null &&
        DateTime.now().difference(cached.fetched) <
            const Duration(minutes: 5)) {
      return Future.value(cached.day);
    }
    return _dailyRequests.putIfAbsent(
      key,
      () => _fetchDay(date).whenComplete(() {
        _dailyRequests.remove(key);
      }),
    );
  }

  Future<DailyPrayers> _fetchDay(DateTime date) async {
    try {
      final raw =
          await _api.get('/prayer-times/today', query: {'date': _date(date)})
              as Map<String, dynamic>;
      final day = DailyPrayers.fromJson(raw);
      if (_date(day.date) != _date(date)) {
        throw const FormatException('Wrong prayer date');
      }
      await _store([raw]);
      return day;
    } catch (_) {
      final stored = await _stored(from: date, to: date);
      if (stored.isNotEmpty) return stored.first;
      rethrow;
    }
  }

  @override
  Future<List<DailyPrayers>> range({
    required DateTime from,
    required DateTime to,
  }) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    if (to.isBefore(from)) {
      return Future.error(ArgumentError('Invalid prayer date range'));
    }
    final cached = <DailyPrayers>[];
    for (
      var date = from;
      !date.isAfter(to);
      date = DateTime(date.year, date.month, date.day + 1)
    ) {
      final value = _memory[_date(date)];
      if (value == null ||
          DateTime.now().difference(value.fetched) >=
              const Duration(minutes: 5)) {
        break;
      }
      cached.add(value.day);
    }
    final count =
        DateTime.utc(
          to.year,
          to.month,
          to.day,
        ).difference(DateTime.utc(from.year, from.month, from.day)).inDays +
        1;
    if (cached.length == count) return Future.value(cached);
    final key = '${_date(from)}/${_date(to)}';
    return _rangeRequests.putIfAbsent(
      key,
      () => _fetchRange(from, to, count).whenComplete(() {
        _rangeRequests.remove(key);
      }),
    );
  }

  Future<List<DailyPrayers>> _fetchRange(
    DateTime from,
    DateTime to,
    int count,
  ) async {
    try {
      final data = await _api.getEnvelope(
        '/prayer-times',
        query: {
          'from': _date(from),
          'to': _date(to),
          'per_page': count.clamp(1, 100),
        },
      );
      final items = (data as Map<String, dynamic>)['data'] as List;
      final valid = <Map<String, dynamic>>[];
      for (final item in items) {
        try {
          final raw = item as Map<String, dynamic>;
          final day = DailyPrayers.fromJson(raw);
          if (!day.date.isBefore(from) && !day.date.isAfter(to)) valid.add(raw);
        } catch (_) {
          /* A malformed day must not discard all cached days. */
        }
      }
      if (valid.isEmpty) throw const FormatException('No valid prayer dates');
      await _store(valid);
      final merged = {
        for (final day in await _stored(from: from, to: to))
          _date(day.date): day,
      };
      for (final raw in valid) {
        final day = DailyPrayers.fromJson(raw);
        merged[_date(day.date)] = day;
      }
      return merged.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    } catch (_) {
      final stored = await _stored(from: from, to: to);
      if (stored.isNotEmpty) return stored;
      rethrow;
    }
  }

  Future<List<DailyPrayers>> _stored({
    required DateTime from,
    required DateTime to,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final byDate = <String, DailyPrayers>{};
    // Read legacy data for upgrades. New writes use independent date keys so a
    // foreground single-day fetch cannot overwrite a background range cache.
    try {
      final legacy =
          jsonDecode(prefs.getString('prayer_times_cache') ?? '[]') as List;
      for (final raw in legacy) {
        try {
          final day = DailyPrayers.fromJson(raw as Map<String, dynamic>);
          byDate[_date(day.date)] = day;
        } catch (_) {}
      }
    } catch (_) {}
    for (
      var date = from;
      !date.isAfter(to);
      date = DateTime(date.year, date.month, date.day + 1)
    ) {
      try {
        final raw = prefs.getString('$_prefix${_date(date)}');
        if (raw == null) continue;
        final day = DailyPrayers.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (_date(day.date) == _date(date)) byDate[_date(date)] = day;
      } catch (_) {}
    }
    return byDate.values
        .where((d) => !d.date.isBefore(from) && !d.date.isAfter(to))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _store(List<Map<String, dynamic>> rawDays) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final now = prayerToday();
    for (final raw in rawDays) {
      final day = DailyPrayers.fromJson(raw);
      final key = _date(day.date);
      _memory[key] = (day: day, fetched: DateTime.now());
      await prefs.setString('$_prefix$key', jsonEncode(raw));
    }
    final oldest = DateTime(now.year, now.month, now.day - 30);
    final newest = DateTime(now.year, now.month, now.day + 90);
    for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      final date = DateTime.tryParse(key.substring(_prefix.length));
      if (date == null || date.isBefore(oldest) || date.isAfter(newest)) {
        await prefs.remove(key);
      }
    }
    if (_memory.length > 150) {
      final keys = _memory.keys.toList();
      for (final key in keys.take(_memory.length - 150)) {
        _memory.remove(key);
      }
    }
  }

  String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
