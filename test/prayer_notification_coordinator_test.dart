import 'dart:async';

import 'package:ckikatowice/data/models/prayer.dart';
import 'package:ckikatowice/data/notifications/prayer_scheduler.dart';
import 'package:ckikatowice/data/notifications/schedule_lock.dart';
import 'package:ckikatowice/data/services/notification_service.dart';
import 'package:ckikatowice/data/services/prayer_service.dart';
import 'package:ckikatowice/state/notification_controller.dart';
import 'package:ckikatowice/state/prayer_notification_coordinator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:ckikatowice/core/utils/prayer_time.dart';

class SerialTestLock implements ScheduleLock {
  Future<void> _tail = Future.value();
  @override
  Future<T> run<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}

class FakeGateway implements NotificationGateway {
  FakeGateway({this.isIOS = false});
  @override
  final bool isIOS;
  bool permission = true;
  bool exact = true;
  int writes = 0;
  int? failAfter;
  bool dropWrites = false;
  final pending = <int, PendingNotificationRequest>{};
  final times = <int, tz.TZDateTime>{};
  final modes = <int, bool>{};
  @override
  bool get isAndroid => !isIOS;
  @override
  tz.Location get prayerLocation => tz.getLocation('Europe/Warsaw');
  @override
  Future<void> init() async {}
  @override
  Future<bool> notificationsEnabled() async => permission;
  @override
  Future<bool> requestNotificationPermission() async => permission;
  @override
  Future<bool> canScheduleExactAlarms() async => exact;
  @override
  Future<bool> requestExactAlarmPermission() async => exact;
  @override
  Future<List<PendingNotificationRequest>> pendingRequests() async =>
      pending.values.toList();
  @override
  Future<void> cancel(int id) async {
    pending.remove(id);
    times.remove(id);
  }

  @override
  Future<void> schedule({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
    required String payload,
    required bool exact,
  }) async {
    if (failAfter != null && writes >= failAfter!) {
      throw StateError('schedule failed');
    }
    writes++;
    if (dropWrites) return;
    pending[id] = PendingNotificationRequest(id, title, body, payload);
    times[id] = when;
    modes[id] = exact;
  }

  @override
  Future<void> scheduleTest({
    required String title,
    required String body,
  }) async {}
  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async => throw StateError('Foreground delivery must not be used');
}

class FakePrayerService implements PrayerService {
  bool fail = false;
  int? missingDay;
  Completer<void>? barrier;
  @override
  Future<List<DailyPrayers>> range({
    required DateTime from,
    required DateTime to,
  }) async {
    await barrier?.future;
    if (fail) throw StateError('offline');
    return [
      for (
        var d = from;
        !d.isAfter(to);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        if (d.day != missingDay) makeDay(d),
    ];
  }

  @override
  Future<DailyPrayers> forDate(DateTime date) async => makeDay(date);
  @override
  Future<DailyPrayers> today() async => makeDay(DateTime(2026, 9, 5));
  static DailyPrayers makeDay(DateTime date) => DailyPrayers(
    date: date,
    slots: const [
      PrayerSlot(name: PrayerName.fajr, time: TimeOfDay(hour: 5, minute: 0)),
      PrayerSlot(name: PrayerName.dhuhr, time: TimeOfDay(hour: 12, minute: 0)),
      PrayerSlot(name: PrayerName.asr, time: TimeOfDay(hour: 16, minute: 0)),
      PrayerSlot(
        name: PrayerName.maghrib,
        time: TimeOfDay(hour: 19, minute: 0),
      ),
      PrayerSlot(name: PrayerName.isha, time: TimeOfDay(hour: 21, minute: 0)),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  initPrayerTimeZones();
  late FakeGateway gateway;
  late FakePrayerService service;
  late PrayerScheduler scheduler;
  late SerialTestLock lock;
  final now = tz.TZDateTime(prayerLocation, 2026, 9, 5);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    gateway = FakeGateway();
    service = FakePrayerService();
    lock = SerialTestLock();
    scheduler = PrayerScheduler(
      prayerService: service,
      gateway: gateway,
      lock: lock,
      now: () => now,
    );
  });
  test('stable IDs survive the scheduler migration', () {
    expect(
      PrayerScheduler.notificationId(DateTime(2026, 7, 21), PrayerName.fajr),
      202607210,
    );
  });
  test(
    'Android retains 30 days without foreground notification delivery',
    () async {
      final status = await scheduler.synchronize();
      expect(status.syncState, PrayerNotificationSyncState.ready);
      expect(status.scheduledCount, 150);
      expect(status.scheduledThrough, DateTime(2026, 10, 4));
      expect(status.nextNotification, DateTime.utc(2026, 9, 5, 3));
    },
  );
  test(
    'unchanged refresh performs no alarm rewrites; missing alarm is repaired',
    () async {
      await scheduler.synchronize();
      final writes = gateway.writes;
      await scheduler.synchronize();
      expect(gateway.writes, writes);
      gateway.pending.remove(gateway.pending.keys.first);
      await scheduler.synchronize();
      expect(gateway.writes, writes + 1);
    },
  );
  test('permission change upgrades inexact alarms', () async {
    gateway.exact = false;
    final first = await scheduler.synchronize();
    expect(first.exactAlarmAvailable, false);
    expect(gateway.modes.values.every((v) => !v), true);
    gateway.exact = true;
    await scheduler.synchronize();
    expect(gateway.modes.values.every((v) => v), true);
    expect(gateway.writes, 300);
  });
  test(
    'iOS respects global pending capacity including unrelated notifications',
    () async {
      gateway = FakeGateway(isIOS: true);
      for (var i = 0; i < 6; i++) {
        gateway.pending[i] = PendingNotificationRequest(i, '', '', 'other');
      }
      scheduler = PrayerScheduler(
        prayerService: service,
        gateway: gateway,
        lock: lock,
        now: () => now,
      );
      final status = await scheduler.synchronize();
      expect(status.scheduledCount, 56);
      expect(gateway.pending.length, lessThanOrEqualTo(63));
      expect(status.scheduledThrough, DateTime(2026, 9, 15));
      expect(gateway.pending[PrayerScheduler.reminderId], isNotNull);
    },
  );
  test('offline refresh preserves pending alerts', () async {
    await scheduler.synchronize();
    final before = gateway.pending.keys.toSet();
    service.fail = true;
    final status = await scheduler.synchronize();
    expect(status.syncState, PrayerNotificationSyncState.failed);
    expect(gateway.pending.keys.toSet(), before);
    expect(status.nextNotification, isNotNull);
  });
  test('muting cancels a prayer while offline and permission denied', () async {
    await scheduler.synchronize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(NotificationController.storageKey, ['isha']);
    service.fail = true;
    gateway.permission = false;
    await scheduler.synchronize();
    expect(
      gateway.pending.values.every((p) => p.payload!.contains(':isha|')),
      true,
    );
    expect(gateway.pending.length, 30);
  });
  test('partial schedule failure does not claim complete coverage', () async {
    gateway.failAfter = 3;
    final status = await scheduler.synchronize();
    expect(status.syncState, PrayerNotificationSyncState.failed);
    expect(status.scheduledCount, 3);
    expect(status.scheduledThrough, isNull);
    gateway.failAfter = null;
    expect((await scheduler.synchronize()).scheduledCount, 150);
  });
  test('missing OS registrations cannot report success', () async {
    gateway.dropWrites = true;
    final status = await scheduler.synchronize();
    expect(status.syncState, PrayerNotificationSyncState.failed);
    expect(status.scheduledCount, 0);
  });
  test('date gaps do not inflate verified coverage', () async {
    service.missingDay = 7;
    final status = await scheduler.synchronize();
    expect(status.scheduledThrough, DateTime(2026, 9, 6));
    expect(status.syncState, PrayerNotificationSyncState.failed);
  });
  test('concurrent foreground mute wins after background refresh', () async {
    service.barrier = Completer<void>();
    final background = scheduler.synchronize();
    await Future<void>.delayed(Duration.zero);
    final preferences = NotificationController();
    final coordinator = PrayerNotificationCoordinator(
      preferences: preferences,
      prayerService: service,
      gateway: gateway,
      localeCode: () => 'en',
      lock: lock,
      now: () => now,
      configureBackground: (_) async {},
    );
    final mute = coordinator.setAll(false);
    service.barrier!.complete();
    await Future.wait([background, mute]);
    expect(gateway.pending, isEmpty);
    coordinator.dispose();
  });
  test('Warsaw DST conversion uses calendar days', () async {
    scheduler = PrayerScheduler(
      prayerService: service,
      gateway: gateway,
      lock: lock,
      now: () => tz.TZDateTime(prayerLocation, 2026, 10, 24),
    );
    await scheduler.synchronize();
    final before =
        gateway.times[PrayerScheduler.notificationId(
          DateTime(2026, 10, 24),
          PrayerName.fajr,
        )]!;
    final after =
        gateway.times[PrayerScheduler.notificationId(
          DateTime(2026, 10, 25),
          PrayerName.fajr,
        )]!;
    expect(after.difference(before), const Duration(hours: 25));
    expect(before.hour, 5);
    expect(after.hour, 5);
  });
}
