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
       _localeCode = localeCode,
       _now = now ?? DateTime.now,
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
  final String Function() _localeCode;
  final DateTime Function() _now;
  final Future<void> Function(bool) _configureBackground;
  PrayerNotificationStatus _status = const PrayerNotificationStatus();
  Future<void>? _activeSync;
  bool _again = false;
  bool _started = false;
  bool _disposed = false;
  bool _requestQueued = false;
  bool _forceQueued = false;
  Timer? _retry;
  Timer? _midnightTimer;
  StreamSubscription<String>? _tapSubscription;
  int _attempt = 0;
  DateTime? _lastForcedResync;

  /// Minimum spacing between resume-triggered forced resyncs, so rapidly
  /// backgrounding/foregrounding the app cannot hammer the platform channel
  /// and the schedule lock.
  static const _minForcedResyncGap = Duration(minutes: 2);

  PrayerNotificationStatus get status => _status;
  Set<PrayerName> get enabled => _preferences.enabled;
  bool get allEnabled => _preferences.allEnabled;
  bool isEnabled(PrayerName name) => _preferences.isEnabled(name);

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _tapSubscription = _gateway.tappedPayloads.listen(_onNotificationPayload);
    unawaited(
      _gateway.consumeLaunchPayload().then((payload) {
        if (payload != null) _onNotificationPayload(payload);
      }),
    );
    _scheduleMidnightRollover();
    await synchronize(requestPermissions: true, force: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Android's pending-notifications list is plugin-side persistence, not
      // an AlarmManager query: after an OEM battery manager purges alarms,
      // that list still shows them as scheduled, so a non-forced sync would
      // see "nothing changed" and leave the app silently dead. Forcing here
      // is what actually repairs a device that stopped notifying while
      // closed. A resume also gets a fresh shot at retrying if the last
      // attempt gave up permanently.
      _attempt = 0;
      _retry?.cancel();
      _retry = null;
      final last = _lastForcedResync;
      final shouldForce =
          last == null || _now().difference(last) >= _minForcedResyncGap;
      if (shouldForce) _lastForcedResync = _now();
      unawaited(synchronize(force: shouldForce));
      _scheduleMidnightRollover();
    } else {
      _retry?.cancel();
      _retry = null;
      _midnightTimer?.cancel();
      _midnightTimer = null;
    }
  }

  void _onNotificationPayload(String payload) {
    // Tapping the "your schedule is running out" reminder should trigger an
    // immediate repair rather than silently doing nothing.
    if (payload.startsWith('coverage|') || payload.startsWith('coverage:')) {
      unawaited(synchronize(force: true));
    }
  }

  void _scheduleMidnightRollover() {
    _midnightTimer?.cancel();
    final now = _now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now) + const Duration(seconds: 2);
    _midnightTimer = Timer(delay, () {
      // A device left open overnight would otherwise keep a scheduling
      // window that shifted a day without ever re-syncing.
      unawaited(synchronize(force: true));
      _scheduleMidnightRollover();
    });
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

  Future<bool> isIgnoringBatteryOptimizations() =>
      _gateway.isIgnoringBatteryOptimizations();

  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _gateway.requestIgnoreBatteryOptimizations();
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
          await _persistLocale();
          if (request && enabled.isNotEmpty) {
            if (!await _gateway.notificationsEnabled()) {
              await _gateway.requestNotificationPermission();
            }
            if (_gateway.isAndroid &&
                await _gateway.notificationsEnabled() &&
                !await _gateway.canScheduleExactAlarms()) {
              await _gateway.requestExactAlarmPermission();
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

  /// Persists the current locale so the scheduler (and the background
  /// isolate, which cannot read app state) always have a value to read,
  /// instead of silently falling back to English.
  Future<void> _persistLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = _localeCode();
    if (['en', 'pl', 'ar'].contains(code)) {
      await prefs.setString('app_locale', code);
    }
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
    _midnightTimer?.cancel();
    unawaited(_tapSubscription?.cancel());
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
