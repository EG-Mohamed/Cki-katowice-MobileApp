import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/prayer.dart';
import '../data/notifications/background_prayers.dart';
import '../data/notifications/notification_status.dart';
import '../data/notifications/prayer_scheduler.dart';
import '../data/notifications/schedule_lock.dart';
import '../data/services/notification_service.dart';
import '../data/services/prayer_service.dart';
import 'notification_controller.dart';

export '../data/notifications/notification_status.dart';

class PrayerNotificationCoordinator extends ChangeNotifier
    with WidgetsBindingObserver {
  PrayerNotificationCoordinator({
    required this._preferences,
    required PrayerService prayerService,
    required NotificationGateway gateway,
    required String Function() localeCode,
    ScheduleLock lock = const DatabaseScheduleLock(),
    DateTime Function()? now,
    Future<void> Function(bool)? configureBackground,
  }) : _gateway = gateway,
       _configureBackground =
           configureBackground ?? BackgroundPrayers.configure,
       _scheduler = PrayerScheduler(
         prayerService: prayerService,
         gateway: gateway,
         lock: lock,
         now: now,
       );

  final NotificationController _preferences;
  final NotificationGateway _gateway;
  final PrayerScheduler _scheduler;
  final Future<void> Function(bool) _configureBackground;
  PrayerNotificationStatus _status = const PrayerNotificationStatus();
  Future<void>? _activeSync;
  bool _again = false;
  bool _started = false;
  bool _disposed = false;
  bool _requestQueued = false;
  bool _forceQueued = false;
  Timer? _retry;
  int _attempt = 0;

  PrayerNotificationStatus get status => _status;
  Set<PrayerName> get enabled => _preferences.enabled;
  bool get allEnabled => _preferences.allEnabled;
  bool isEnabled(PrayerName name) => _preferences.isEnabled(name);

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await synchronize(requestPermissions: true, force: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(synchronize());
    } else {
      _retry?.cancel();
      _retry = null;
    }
  }

  Future<void> togglePrayer(PrayerName name) =>
      setPrayerEnabled(name, !isEnabled(name));
  Future<void> setPrayerEnabled(PrayerName name, bool value) async {
    await _scheduler.lock.run(() => _preferences.setEnabled(name, value));
    if (_disposed) return;
    notifyListeners();
    await synchronize(requestPermissions: value);
  }

  Future<void> setAll(bool value) async {
    await _scheduler.lock.run(() => _preferences.setAll(value));
    if (_disposed) return;
    notifyListeners();
    await synchronize(requestPermissions: value);
  }

  Future<void> requestExactAlarmAccess() async {
    try {
      await _gateway.requestExactAlarmPermission();
      await synchronize(force: true);
    } catch (e) {
      _failed(e);
    }
  }

  Future<bool> scheduleLockScreenTest({
    required String title,
    required String body,
  }) async {
    try {
      if (!await _gateway.notificationsEnabled() &&
          !await _gateway.requestNotificationPermission()) {
        _update(
          _status.copyWith(permission: PrayerNotificationPermission.denied),
        );
        return false;
      }
      if (_gateway.isAndroid && !await _gateway.canScheduleExactAlarms()) {
        await _gateway.requestExactAlarmPermission();
      }
      await _scheduler.lock.run(
        () => _gateway.scheduleTest(title: title, body: body),
      );
      unawaited(synchronize());
      return true;
    } catch (e) {
      _failed(e);
      return false;
    }
  }

  Future<void> synchronize({
    bool requestPermissions = false,
    bool force = false,
  }) {
    if (_disposed) return Future.value();
    _requestQueued |= requestPermissions;
    _forceQueued |= force;
    if (_activeSync != null) {
      _again = true;
      return _activeSync!;
    }
    final completer = Completer<void>();
    _activeSync = completer.future;
    () async {
      do {
        _again = false;
        final request = _requestQueued;
        final repair = _forceQueued;
        _forceQueued = false;
        _requestQueued = false;
        _update(
          _status.copyWith(
            syncState: PrayerNotificationSyncState.syncing,
            clearError: true,
          ),
        );
        try {
          await _gateway.init();
          await _preferences.load();
          if (request && enabled.isNotEmpty) {
            if (!await _gateway.notificationsEnabled()) {
              await _gateway.requestNotificationPermission();
            }
            if (_gateway.isAndroid &&
                await _gateway.notificationsEnabled() &&
                !await _gateway.canScheduleExactAlarms()) {
              final prefs = await SharedPreferences.getInstance();
              if (!(prefs.getBool('prayer_notification_exact_asked') ??
                  false)) {
                await prefs.setBool('prayer_notification_exact_asked', true);
                await _gateway.requestExactAlarmPermission();
              }
            }
          }
          Object? registrationError;
          try {
            await _configureBackground(enabled.isNotEmpty);
          } catch (e) {
            registrationError = e;
          }
          final result = await _scheduler.synchronize(force: repair);
          _update(result);
          if (registrationError != null) _failed(registrationError);
          if (registrationError != null ||
              result.syncState == PrayerNotificationSyncState.failed) {
            _scheduleRetry();
          } else {
            _attempt = 0;
            _retry?.cancel();
            _retry = null;
          }
        } catch (e) {
          _failed(e);
          _scheduleRetry();
        }
      } while (_again && !_disposed);
    }().whenComplete(() {
      _activeSync = null;
      completer.complete();
    });
    return completer.future;
  }

  void _failed(Object error) => _update(
    _status.copyWith(
      syncState: PrayerNotificationSyncState.failed,
      lastError: error.toString(),
    ),
  );
  void _scheduleRetry() {
    if (_disposed ||
        !_started ||
        _retry != null ||
        _attempt >= 4 ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      return;
    }
    final delays = [5, 30, 120, 600];
    _retry = Timer(Duration(seconds: delays[_attempt++]), () {
      _retry = null;
      unawaited(synchronize());
    });
  }

  void _update(PrayerNotificationStatus value) {
    if (_disposed) return;
    _status = value;
    notifyListeners();
  }

  @visibleForTesting
  static int notificationId(DateTime date, PrayerName name) =>
      PrayerScheduler.notificationId(date, name);
  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
