import 'dart:async';
import 'package:ckikatowice/core/utils/prayer_time.dart';
import 'package:ckikatowice/data/models/prayer.dart';
import 'package:ckikatowice/data/services/prayer_service.dart';
import 'package:ckikatowice/state/prayer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

class _Service implements PrayerService {
  final requests = <DateTime, Completer<DailyPrayers>>{};
  @override
  Future<DailyPrayers> forDate(DateTime date) =>
      requests.putIfAbsent(date, Completer.new).future;
  @override
  Future<List<DailyPrayers>> range({
    required DateTime from,
    required DateTime to,
  }) => throw UnimplementedError();
  @override
  Future<DailyPrayers> today() => throw UnimplementedError();
}

DailyPrayers _day(int date, int fajrMinute) => DailyPrayers(
  date: DateTime(2026, 9, date),
  slots: [
    PrayerSlot(
      name: PrayerName.fajr,
      time: TimeOfDay(hour: 5, minute: fajrMinute),
    ),
    const PrayerSlot(
      name: PrayerName.isha,
      time: TimeOfDay(hour: 21, minute: 0),
    ),
  ],
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  initPrayerTimeZones();
  test(
    'after Isha uses actual tomorrow Fajr, not today plus 24 hours',
    () async {
      final service = _Service();
      final controller = PrayerController(
        service,
        now: () => tz.TZDateTime(prayerLocation, 2026, 9, 5, 22),
      );
      final load = controller.load();
      service.requests[DateTime(2026, 9, 5)]!.complete(_day(5, 0));
      await Future<void>.delayed(Duration.zero);
      expect(
        controller.nextPrayer,
        isNull,
        reason: 'Never invent tomorrow when data is unavailable',
      );
      service.requests[DateTime(2026, 9, 6)]!.complete(_day(6, 7));
      await load;
      await Future<void>.delayed(Duration.zero);
      expect(controller.remaining, const Duration(hours: 7, minutes: 7));
      expect(controller.nextPrayer!.time.minute, 7);
      controller.dispose();
    },
  );
  test('older request cannot overwrite a newer selected date', () async {
    final service = _Service();
    final controller = PrayerController(
      service,
      now: () => tz.TZDateTime(prayerLocation, 2026, 9, 5, 12),
    );
    final first = controller.load(date: DateTime(2026, 9, 7));
    final second = controller.load(date: DateTime(2026, 9, 8));
    service.requests[DateTime(2026, 9, 8)]!.complete(_day(8, 8));
    await second;
    service.requests[DateTime(2026, 9, 7)]!.complete(_day(7, 7));
    await first;
    expect(controller.day!.date, DateTime(2026, 9, 8));
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(controller.selectedDate, DateTime(2026, 9, 8));
    controller.dispose();
  });
  test('disposing during fetch does not notify or restart a timer', () async {
    final service = _Service();
    final controller = PrayerController(service);
    final load = controller.load(date: DateTime(2026, 9, 8));
    controller.dispose();
    service.requests[DateTime(2026, 9, 8)]!.complete(_day(8, 0));
    await load;
  });
}
