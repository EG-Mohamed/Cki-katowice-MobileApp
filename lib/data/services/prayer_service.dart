import '../api/api_client.dart';
import '../models/prayer.dart';

abstract class PrayerService {
  Future<DailyPrayers> today();
  Future<DailyPrayers> forDate(DateTime date);
}

class ApiPrayerService implements PrayerService {
  const ApiPrayerService(this._api);

  final ApiClient _api;

  @override
  Future<DailyPrayers> today() async {
    return forDate(DateTime.now());
  }

  @override
  Future<DailyPrayers> forDate(DateTime date) async {
    final data = await _api.get(
      '/prayer-times/today',
      query: {'date': _dateValue(date)},
    );
    return DailyPrayers.fromJson(data as Map<String, dynamic>);
  }

  String _dateValue(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
