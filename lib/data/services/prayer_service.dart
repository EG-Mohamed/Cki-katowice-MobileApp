import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

  static const String _storeKey = 'prayer_times_cache';

  final ApiClient _api;
  DateTime? _rangeFetchedAt;
  DateTime? _rangeFrom;
  DateTime? _rangeTo;
  List<DailyPrayers>? _rangeCache;
  List<Map<String, dynamic>>? _storedRaw;

  @override
  Future<DailyPrayers> today() async {
    return forDate(DateTime.now());
  }

  @override
  Future<DailyPrayers> forDate(DateTime date) async {
    final cached = _cachedDay(date);
    if (cached != null) return cached;
    try {
      final data = await _api.get(
        '/prayer-times/today',
        query: {'date': _dateValue(date)},
      );
      return DailyPrayers.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      final stored = await _storedDay(date);
      if (stored != null) return stored;
      rethrow;
    }
  }

  Future<DailyPrayers?> _storedDay(DateTime date) async {
    for (final day in await _loadStored()) {
      if (day.date.year == date.year &&
          day.date.month == date.month &&
          day.date.day == date.day) {
        return day;
      }
    }
    return null;
  }

  Future<List<DailyPrayers>> _loadStored() async {
    final raw = _storedRaw ?? await _readStore();
    try {
      return raw.map(DailyPrayers.fromJson).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _readStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_storeKey);
      if (value == null) return const [];
      final decoded = (jsonDecode(value) as List).cast<Map<String, dynamic>>();
      _storedRaw = decoded;
      return decoded;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeStore(List<Map<String, dynamic>> items) async {
    _storedRaw = items;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storeKey, jsonEncode(items));
    } catch (_) {}
  }

  @override
  Future<List<DailyPrayers>> range({
    required DateTime from,
    required DateTime to,
  }) async {
    final fetchedAt = _rangeFetchedAt;
    if (_rangeFrom == from &&
        _rangeTo == to &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < const Duration(minutes: 5) &&
        _rangeCache != null) {
      return _rangeCache!;
    }
    final days = to.difference(from).inDays + 1;
    try {
      final data = await _api.getEnvelope(
        '/prayer-times',
        query: {
          'from': _dateValue(from),
          'to': _dateValue(to),
          'per_page': days.clamp(1, 100),
        },
      );
      final items = (data as Map<String, dynamic>)['data'] as List? ?? const [];
      final raw = items.cast<Map<String, dynamic>>();
      final result = raw.map(DailyPrayers.fromJson).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      _rangeFrom = from;
      _rangeTo = to;
      _rangeFetchedAt = DateTime.now();
      _rangeCache = result;
      await _writeStore(raw);
      return result;
    } catch (_) {
      final stored = await _loadStored();
      final usable = stored
          .where((day) => !day.date.isBefore(from) && !day.date.isAfter(to))
          .toList();
      if (usable.isNotEmpty) return usable;
      rethrow;
    }
  }

  DailyPrayers? _cachedDay(DateTime date) {
    final fetchedAt = _rangeFetchedAt;
    if (fetchedAt == null ||
        DateTime.now().difference(fetchedAt) >= const Duration(minutes: 5)) {
      return null;
    }
    for (final day in _rangeCache ?? const <DailyPrayers>[]) {
      if (day.date.year == date.year &&
          day.date.month == date.month &&
          day.date.day == date.day) {
        return day;
      }
    }
    return null;
  }

  String _dateValue(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
