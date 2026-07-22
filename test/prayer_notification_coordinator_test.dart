import 'package:ckikatowice/data/models/prayer.dart';
import 'package:ckikatowice/data/services/notification_service.dart';
import 'package:ckikatowice/data/services/prayer_service.dart';
import 'package:ckikatowice/state/notification_controller.dart';
import 'package:ckikatowice/state/prayer_notification_coordinator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('stable IDs differ by date and prayer', () {
    final date = DateTime(2026, 7, 21);
    expect(
      PrayerNotificationCoordinator.notificationId(date, PrayerName.fajr),
      202607210,
    );
    expect(
      PrayerNotificationCoordinator.notificationId(date, PrayerName.isha),
      202607215,
    );
  });

  test('iOS horizon stays within the 64 pending notification limit', () async {
    final preferences = NotificationController();
    await preferences.setAll(true);
    final gateway = _FakeGateway(isIOS: true);
    final coordinator = PrayerNotificationCoordinator(
      preferences: preferences,
      prayerService: _FakePrayerService(),
      gateway: gateway,
      localeCode: () => 'en',
    );

    await coordinator.synchronize();

    expect(gateway.scheduled, isNotEmpty);
    expect(gateway.scheduled.length, lessThanOrEqualTo(60));
    expect(
      coordinator.status.scheduledCount,
      gateway.scheduled.length,
      reason: coordinator.status.lastError,
    );
    expect(coordinator.status.syncState, PrayerNotificationSyncState.ready);
  });

  test(
    'denied notification permission does not replace pending alarms',
    () async {
      final preferences = NotificationController();
      await preferences.setAll(true);
      final gateway = _FakeGateway(permissionGranted: false)
        ..seedPending = const [
          PendingNotificationRequest(42, 'old', 'old', 'prayer:old'),
        ];
      final coordinator = PrayerNotificationCoordinator(
        preferences: preferences,
        prayerService: _FakePrayerService(),
        gateway: gateway,
        localeCode: () => 'en',
      );

      await coordinator.synchronize();

      expect(gateway.cancelled, isEmpty);
      expect(
        coordinator.status.permission,
        PrayerNotificationPermission.denied,
      );
    },
  );

  test('missing exact access uses inexact while-idle scheduling', () async {
    final preferences = NotificationController();
    await preferences.setAll(true);
    final gateway = _FakeGateway(exactAvailable: false);
    final coordinator = PrayerNotificationCoordinator(
      preferences: preferences,
      prayerService: _FakePrayerService(),
      gateway: gateway,
      localeCode: () => 'en',
    );

    await coordinator.synchronize();

    expect(gateway.scheduled, isNotEmpty);
    expect(gateway.scheduled.every((item) => !item.exact), isTrue);
    expect(
      coordinator.status.exactAlarmAvailable,
      isFalse,
      reason: coordinator.status.lastError,
    );
  });

  test('range failure leaves existing pending alarms untouched', () async {
    final preferences = NotificationController();
    await preferences.setAll(true);
    final gateway = _FakeGateway()
      ..seedPending = const [
        PendingNotificationRequest(42, 'old', 'old', 'prayer:old'),
      ];
    final coordinator = PrayerNotificationCoordinator(
      preferences: preferences,
      prayerService: _FakePrayerService(shouldFail: true),
      gateway: gateway,
      localeCode: () => 'en',
    );

    await coordinator.synchronize();

    expect(gateway.cancelled, isEmpty);
    expect(coordinator.status.syncState, PrayerNotificationSyncState.failed);
  });
}

class _ScheduledCall {
  const _ScheduledCall({required this.id, required this.exact});
  final int id;
  final bool exact;
}

class _FakeGateway implements NotificationGateway {
  _FakeGateway({
    this.isIOS = false,
    this.permissionGranted = true,
    this.exactAvailable = true,
  });

  @override
  final bool isIOS;
  bool permissionGranted;
  bool exactAvailable;
  List<PendingNotificationRequest> seedPending = const [];
  final List<_ScheduledCall> scheduled = [];
  final List<int> cancelled = [];

  @override
  bool get isAndroid => !isIOS;

  @override
  tz.Location get prayerLocation => tz.UTC;

  @override
  Future<bool> canScheduleExactAlarms() async => exactAvailable;

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<void> init() async {}

  @override
  Future<bool> notificationsEnabled() async => permissionGranted;

  @override
  Future<List<PendingNotificationRequest>> pendingRequests() async => [
    ...seedPending,
    for (final item in scheduled)
      PendingNotificationRequest(item.id, 'title', 'body', 'prayer:new'),
  ];

  @override
  Future<bool> requestExactAlarmPermission() async => exactAvailable;

  @override
  Future<bool> requestNotificationPermission() async => permissionGranted;

  @override
  Future<void> schedule({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
    required String payload,
    required bool exact,
  }) async {
    scheduled.add(_ScheduledCall(id: id, exact: exact));
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
  }) async {
    shown.add(id);
  }

  final List<int> shown = [];
}

class _FakePrayerService implements PrayerService {
  _FakePrayerService({this.shouldFail = false});
  final bool shouldFail;

  @override
  Future<DailyPrayers> forDate(DateTime date) async => _day(date);

  @override
  Future<List<DailyPrayers>> range({
    required DateTime from,
    required DateTime to,
  }) async {
    if (shouldFail) throw StateError('offline');
    return [
      for (var i = 0; i <= to.difference(from).inDays; i++)
        _day(from.add(Duration(days: i))),
    ];
  }

  @override
  Future<DailyPrayers> today() async => _day(DateTime.now());

  DailyPrayers _day(DateTime date) => DailyPrayers(
    date: date,
    slots: const [
      PrayerSlot(name: PrayerName.fajr, time: TimeOfDay(hour: 23, minute: 50)),
      PrayerSlot(name: PrayerName.dhuhr, time: TimeOfDay(hour: 23, minute: 51)),
      PrayerSlot(name: PrayerName.asr, time: TimeOfDay(hour: 23, minute: 52)),
      PrayerSlot(
        name: PrayerName.maghrib,
        time: TimeOfDay(hour: 23, minute: 53),
      ),
      PrayerSlot(name: PrayerName.isha, time: TimeOfDay(hour: 23, minute: 54)),
    ],
  );
}
