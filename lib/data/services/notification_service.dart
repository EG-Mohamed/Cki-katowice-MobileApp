import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/prayer_time.dart' as prayer_time;

abstract class NotificationGateway {
  bool get isAndroid;
  bool get isIOS;
  tz.Location get prayerLocation;

  Future<void> init();
  Future<bool> notificationsEnabled();
  Future<bool> requestNotificationPermission();
  Future<bool> canScheduleExactAlarms();
  Future<bool> requestExactAlarmPermission();
  Future<List<PendingNotificationRequest>> pendingRequests();
  Future<void> schedule({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
    required String payload,
    required bool exact,
  });
  Future<void> cancel(int id);
  Future<void> scheduleTest({required String title, required String body});
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  });
}

class NotificationService implements NotificationGateway {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'adhan_prayer_times_v2';
  static const String payloadPrefix = 'prayer:';
  static const int testNotificationId = 9999;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  @override
  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  tz.Location get prayerLocation => prayer_time.prayerLocation;

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      'Adhan & prayer times',
      channelDescription: 'Adhan reminders at each prayer time',
      icon: 'ic_stat_notification',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      sound: 'adhan.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  @override
  Future<void> init() async {
    if (_ready) return;
    prayer_time.initPrayerTimeZones();
    const initialization = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: initialization);
    await _createChannel();
    _ready = true;
  }

  Future<void> _createChannel() async {
    if (!isAndroid) return;
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        'Adhan & prayer times',
        description: 'Adhan reminders at each prayer time',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adhan'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> notificationsEnabled() async {
    await init();
    if (isAndroid) return await _android?.areNotificationsEnabled() ?? true;
    if (isIOS) return (await _ios?.checkPermissions())?.isEnabled ?? false;
    return true;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    await init();
    if (isIOS) {
      return await _ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    if (isAndroid) {
      return await _android?.requestNotificationsPermission() ?? true;
    }
    return true;
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    await init();
    if (!isAndroid) return true;
    return await _android?.canScheduleExactNotifications() ?? true;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    await init();
    if (!isAndroid) return true;
    return await _android?.requestExactAlarmsPermission() ?? false;
  }

  @override
  Future<List<PendingNotificationRequest>> pendingRequests() async {
    await init();
    return _plugin.pendingNotificationRequests();
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
    await init();
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: when,
      notificationDetails: _details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    await init();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
      payload: payload,
    );
  }

  @override
  Future<void> scheduleTest({
    required String title,
    required String body,
  }) async {
    await init();
    final exact = await canScheduleExactAlarms();
    final when = tz.TZDateTime.now(
      prayerLocation,
    ).add(const Duration(seconds: 15));
    await schedule(
      id: testNotificationId,
      when: when,
      title: title,
      body: body,
      payload: 'test:lock-screen',
      exact: exact,
    );
  }
}
