import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'adhan_prayer_times';

  bool _ready = false;

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Adhan & prayer times',
      channelDescription: 'Adhan reminders at each prayer time',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ),
    iOS: DarwinNotificationDetails(presentSound: true, sound: 'adhan.mp3'),
  );

  Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Warsaw'));
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _createChannel();
    _ready = true;
  }

  Future<void> _createChannel() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
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

  Future<bool> requestPermission() async {
    await init();
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final androidGranted = await _android?.requestNotificationsPermission();
    await _android?.requestExactAlarmsPermission();
    return iosGranted ?? androidGranted ?? true;
  }

  Future<bool> canScheduleExactAlarms() async {
    await init();
    final result = await _android?.canScheduleExactNotifications();
    return result ?? true;
  }

  Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(9999, title, body, _details);
  }

  Future<void> scheduleForDay({
    required DailyPrayers day,
    required Set<PrayerName> enabled,
    required String Function(PrayerName) titleFor,
    required String title,
  }) async {
    await init();
    await _plugin.cancelAll();
    final now = DateTime.now();
    int id = 0;
    for (final slot in day.notifiable) {
      if (!enabled.contains(slot.name)) continue;
      var when = slot.dateTimeOn(day.date);
      if (when.isBefore(now)) {
        when = when.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id++,
        title,
        titleFor(slot.name),
        tz.TZDateTime.from(when, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
