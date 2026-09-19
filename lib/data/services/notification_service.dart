import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
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
  Future<bool> isIgnoringBatteryOptimizations();
  Future<void> requestIgnoreBatteryOptimizations();
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

  /// A payload from a tapped notification, or one the app was launched from.
  /// Consumed once; the same payload is not returned twice.
  Stream<String> get tappedPayloads;
  Future<String?> consumeLaunchPayload();
}

class NotificationService implements NotificationGateway {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Bumped whenever the channel's sound/importance/behaviour changes:
  /// Android freezes those settings on the first create, so an old
  /// installation only picks up a fix if we create a new channel id and
  /// drop the previous one.
  static const String channelId = 'adhan_prayer_times_v3';
  static const List<String> _staleChannelIds = ['adhan_prayer_times_v2'];
  static const String coverageChannelId = 'schedule_status_v2';
  static const String payloadPrefix = 'prayer:';
  static const int testNotificationId = 9999;

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initializing;
  final _tappedPayloads = StreamController<String>.broadcast();
  bool _launchPayloadConsumed = false;

  @override
  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  tz.Location get prayerLocation => prayer_time.prayerLocation;

  @override
  Stream<String> get tappedPayloads => _tappedPayloads.stream;

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

  NotificationDetails get _coverageDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      coverageChannelId,
      'Prayer schedule status',
      channelDescription: 'Warns when scheduled prayer reminders are running out',
      importance: Importance.defaultImportance,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: false),
  );

  @override
  Future<void> init() =>
      _initializing ??= _initialize().catchError((Object error) {
        _initializing = null;
        throw error;
      });

  Future<void> _initialize() async {
    prayer_time.initPrayerTimeZones();
    const initialization = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: initialization,
      onDidReceiveNotificationResponse: _onResponse,
    );
    await _createChannels();
  }

  void _onResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _tappedPayloads.add(payload);
    }
  }

  Future<void> _createChannels() async {
    if (!isAndroid) return;
    for (final staleId in _staleChannelIds) {
      await _android?.deleteNotificationChannel(channelId: staleId);
    }
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
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        coverageChannelId,
        'Prayer schedule status',
        description:
            'Warns when scheduled prayer reminders are running out',
        importance: Importance.defaultImportance,
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
    if (isAndroid) {
      if (!(await _android?.areNotificationsEnabled() ?? false)) return false;
      final channels = await _android?.getNotificationChannels();
      for (final channel in channels ?? <AndroidNotificationChannel>[]) {
        if (channel.id == channelId && channel.importance == Importance.none) {
          return false;
        }
      }
      return true;
    }
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
      return await _android?.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    await init();
    if (!isAndroid) return true;
    return await _android?.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    await init();
    if (!isAndroid) return true;
    return await _android?.requestExactAlarmsPermission() ?? false;
  }

  @override
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!isAndroid) return true;
    return await ph.Permission.ignoreBatteryOptimizations.isGranted;
  }

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {
    if (!isAndroid) return;
    await ph.Permission.ignoreBatteryOptimizations.request();
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
      notificationDetails: payload.startsWith('coverage:')
          ? _coverageDetails
          : _details,
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

  @override
  Future<String?> consumeLaunchPayload() async {
    if (_launchPayloadConsumed) return null;
    _launchPayloadConsumed = true;
    await init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }
}
