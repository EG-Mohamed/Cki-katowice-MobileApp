import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/models/prayer.dart';
import '../data/services/notification_service.dart';
import '../data/services/prayer_service.dart';
import 'notification_controller.dart';

enum PrayerNotificationPermission { unknown, granted, denied }

enum PrayerNotificationSyncState { idle, syncing, ready, failed }

class PrayerNotificationStatus {
  const PrayerNotificationStatus({
    this.permission = PrayerNotificationPermission.unknown,
    this.exactAlarmAvailable = true,
    this.syncState = PrayerNotificationSyncState.idle,
    this.scheduledCount = 0,
    this.scheduledThrough,
    this.nextNotification,
    this.lastError,
  });

  final PrayerNotificationPermission permission;
  final bool exactAlarmAvailable;
  final PrayerNotificationSyncState syncState;
  final int scheduledCount;
  final DateTime? scheduledThrough;
  final DateTime? nextNotification;
  final String? lastError;

  PrayerNotificationStatus copyWith({
    PrayerNotificationPermission? permission,
    bool? exactAlarmAvailable,
    PrayerNotificationSyncState? syncState,
    int? scheduledCount,
    DateTime? scheduledThrough,
    bool clearScheduledThrough = false,
    DateTime? nextNotification,
    bool clearNextNotification = false,
    String? lastError,
    bool clearError = false,
  }) {
    return PrayerNotificationStatus(
      permission: permission ?? this.permission,
      exactAlarmAvailable: exactAlarmAvailable ?? this.exactAlarmAvailable,
      syncState: syncState ?? this.syncState,
      scheduledCount: scheduledCount ?? this.scheduledCount,
      scheduledThrough: clearScheduledThrough
          ? null
          : scheduledThrough ?? this.scheduledThrough,
      nextNotification: clearNextNotification
          ? null
          : nextNotification ?? this.nextNotification,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}

class PrayerNotificationCoordinator extends ChangeNotifier
    with WidgetsBindingObserver {
  PrayerNotificationCoordinator({
    required NotificationController preferences,
    required PrayerService prayerService,
    required NotificationGateway gateway,
    required String Function() localeCode,
  }) : // These keep the public constructor labels descriptive while fields
       // remain encapsulated inside the coordinator.
       // ignore: prefer_initializing_formals
       _preferences = preferences,
       // ignore: prefer_initializing_formals
       _prayerService = prayerService,
       // ignore: prefer_initializing_formals
       _gateway = gateway,
       // ignore: prefer_initializing_formals
       _localeCode = localeCode;

  static const String _coverageKey = 'prayer_notification_coverage';
  static const String _nextKey = 'prayer_notification_next';
  static const String _exactAskedKey = 'prayer_notification_exact_asked';
  static const String _payloadPrefix = NotificationService.payloadPrefix;
  static const int _iosPendingLimit = 60;
  static const List<Duration> _retryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 10),
  ];

  final NotificationController _preferences;
  final PrayerService _prayerService;
  final NotificationGateway _gateway;
  final String Function() _localeCode;

  PrayerNotificationStatus _status = const PrayerNotificationStatus();
  Future<void>? _activeSync;
  bool _syncAgain = false;
  bool _queuedPermissionRequest = false;
  bool _queuedForce = false;
  bool _started = false;
  bool _everSucceeded = false;
  int _retryAttempt = 0;
  Timer? _retryTimer;
  DateTime? _lastResumeDate;

  bool get everSucceeded => _everSucceeded;

  PrayerNotificationStatus get status => _status;
  Set<PrayerName> get enabled => _preferences.enabled;
  bool get allEnabled => _preferences.allEnabled;
  bool isEnabled(PrayerName name) => _preferences.isEnabled(name);

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await _gateway.init();
    await _loadMetadata();
    await _ensureExactAlarmAccess();
    await synchronize(requestPermissions: true);
  }

  Future<void> _ensureExactAlarmAccess() async {
    if (!_gateway.isAndroid) return;
    if (await _gateway.canScheduleExactAlarms()) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_exactAskedKey) ?? false) return;
    await prefs.setBool(_exactAskedKey, true);
    await _gateway.requestExactAlarmPermission();
  }

  Future<void> showNow(DailyPrayers day, PrayerSlot slot) async {
    if (!_preferences.isEnabled(slot.name)) return;
    if (!await _gateway.notificationsEnabled()) return;
    await _gateway.show(
      id: notificationId(day.date, slot.name),
      title: _titleForLocale(_localeCode(), slot.name),
      body: _bodyForLocale(_localeCode()),
      payload: '$_payloadPrefix${_dateValue(day.date)}:${slot.name.name}',
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = tz.TZDateTime.now(_gateway.prayerLocation);
    final today = DateTime(now.year, now.month, now.day);
    final dateChanged = _lastResumeDate == null || _lastResumeDate != today;
    _lastResumeDate = today;
    unawaited(synchronize(force: dateChanged || _coverageIsLow(now)));
  }

  bool _coverageIsLow(tz.TZDateTime now) {
    final through = _status.scheduledThrough;
    if (through == null) return true;
    final end = DateTime(through.year, through.month, through.day);
    final today = DateTime(now.year, now.month, now.day);
    return end.difference(today).inDays < 3;
  }

  Future<void> togglePrayer(PrayerName name) async {
    await setPrayerEnabled(name, !isEnabled(name));
  }

  Future<void> setPrayerEnabled(PrayerName name, bool value) async {
    await _preferences.setEnabled(name, value);
    notifyListeners();
    await synchronize(requestPermissions: value, force: true);
  }

  Future<void> setAll(bool value) async {
    await _preferences.setAll(value);
    notifyListeners();
    await synchronize(requestPermissions: value, force: true);
  }

  Future<bool> scheduleLockScreenTest({
    required String title,
    required String body,
  }) async {
    var granted = await _gateway.notificationsEnabled();
    if (!granted) granted = await _gateway.requestNotificationPermission();
    if (!granted) {
      _setStatus(
        _status.copyWith(permission: PrayerNotificationPermission.denied),
      );
      return false;
    }
    var exact = await _gateway.canScheduleExactAlarms();
    if (!exact && _gateway.isAndroid) {
      await _gateway.requestExactAlarmPermission();
      exact = await _gateway.canScheduleExactAlarms();
    }
    await _gateway.scheduleTest(title: title, body: body);
    _setStatus(
      _status.copyWith(
        permission: PrayerNotificationPermission.granted,
        exactAlarmAvailable: exact,
      ),
    );
    return true;
  }

  Future<void> requestExactAlarmAccess() async {
    await _gateway.requestExactAlarmPermission();
    await synchronize(force: true);
  }

  Future<void> synchronize({
    bool requestPermissions = false,
    bool force = true,
  }) {
    final running = _activeSync;
    if (running != null) {
      _syncAgain = true;
      _queuedPermissionRequest |= requestPermissions;
      _queuedForce |= force;
      return running;
    }
    final operation = () async {
      var shouldRequestPermission = requestPermissions;
      var shouldForce = force;
      do {
        _syncAgain = false;
        _queuedPermissionRequest = false;
        _queuedForce = false;
        await _synchronize(
          requestPermissions: shouldRequestPermission,
          force: shouldForce,
        );
        shouldRequestPermission = _queuedPermissionRequest;
        shouldForce = _queuedForce;
      } while (_syncAgain);
    }();
    _activeSync = operation;
    return operation.whenComplete(() => _activeSync = null);
  }

  Future<void> _synchronize({
    required bool requestPermissions,
    required bool force,
  }) async {
    _setStatus(
      _status.copyWith(
        syncState: PrayerNotificationSyncState.syncing,
        clearError: true,
      ),
    );
    try {
      if (_preferences.enabled.isEmpty) {
        await _cancelManaged();
        await _saveMetadata(null, null);
        _setStatus(
          _status.copyWith(
            syncState: PrayerNotificationSyncState.ready,
            scheduledCount: 0,
            clearScheduledThrough: true,
            clearNextNotification: true,
          ),
        );
        return;
      }

      var permission = await _gateway.notificationsEnabled();
      if (!permission && requestPermissions) {
        permission = await _gateway.requestNotificationPermission();
      }
      if (!permission) {
        _setStatus(
          _status.copyWith(
            permission: PrayerNotificationPermission.denied,
            syncState: PrayerNotificationSyncState.ready,
          ),
        );
        return;
      }

      var exact = await _gateway.canScheduleExactAlarms();
      final location = _gateway.prayerLocation;
      final now = tz.TZDateTime.now(location);
      if (!force && !_coverageIsLow(now)) {
        await _refreshPendingStatus(permission: permission, exact: exact);
        return;
      }

      final from = DateTime(now.year, now.month, now.day);
      final horizon = _gateway.isIOS ? 12 : 30;
      final to = from.add(Duration(days: horizon - 1));
      final days = await _prayerService.range(from: from, to: to);
      if (days.isEmpty) throw StateError('No prayer times returned');

      final scheduledIds = <int>{};
      final limit = _gateway.isIOS ? _iosPendingLimit : null;
      DateTime? next;
      scheduling:
      for (final day in days) {
        for (final slot in day.notifiable) {
          if (!_preferences.isEnabled(slot.name)) continue;
          if (limit != null && scheduledIds.length >= limit) break scheduling;
          final when = tz.TZDateTime(
            location,
            day.date.year,
            day.date.month,
            day.date.day,
            slot.time.hour,
            slot.time.minute,
          );
          if (!when.isAfter(now)) continue;
          final id = notificationId(day.date, slot.name);
          await _gateway.schedule(
            id: id,
            when: when,
            title: _titleForLocale(_localeCode(), slot.name),
            body: _bodyForLocale(_localeCode()),
            payload: '$_payloadPrefix${_dateValue(day.date)}:${slot.name.name}',
            exact: exact,
          );
          scheduledIds.add(id);
          final value = when.toUtc();
          if (next == null || value.isBefore(next)) next = value;
        }
      }

      final old = await _managedPending();
      for (final request in old) {
        if (!scheduledIds.contains(request.id)) {
          await _gateway.cancel(request.id);
        }
      }

      final coverage = DateTime(
        days.last.date.year,
        days.last.date.month,
        days.last.date.day,
      );
      await _saveMetadata(coverage, next);
      _everSucceeded = true;
      _retryAttempt = 0;
      _retryTimer?.cancel();
      _retryTimer = null;
      _setStatus(
        PrayerNotificationStatus(
          permission: PrayerNotificationPermission.granted,
          exactAlarmAvailable: exact,
          syncState: PrayerNotificationSyncState.ready,
          scheduledCount: scheduledIds.length,
          scheduledThrough: coverage,
          nextNotification: next,
        ),
      );
    } catch (error) {
      _setStatus(
        _status.copyWith(
          syncState: PrayerNotificationSyncState.failed,
          lastError: error.toString(),
        ),
      );
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_retryTimer != null) return;
    final index = _retryAttempt.clamp(0, _retryDelays.length - 1);
    _retryAttempt++;
    _retryTimer = Timer(_retryDelays[index], () {
      _retryTimer = null;
      unawaited(synchronize(force: true));
    });
  }

  Future<void> _refreshPendingStatus({
    required bool permission,
    required bool exact,
  }) async {
    final pending = await _managedPending();
    _setStatus(
      _status.copyWith(
        permission: permission
            ? PrayerNotificationPermission.granted
            : PrayerNotificationPermission.denied,
        exactAlarmAvailable: exact,
        syncState: PrayerNotificationSyncState.ready,
        scheduledCount: pending.length,
      ),
    );
  }

  Future<List<PendingNotificationRequest>> _managedPending() async {
    final pending = await _gateway.pendingRequests();
    return pending
        .where((request) => request.payload?.startsWith(_payloadPrefix) == true)
        .toList();
  }

  Future<void> _cancelManaged() async {
    for (final request in await _managedPending()) {
      await _gateway.cancel(request.id);
    }
  }

  Future<void> _loadMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final coverage = DateTime.tryParse(prefs.getString(_coverageKey) ?? '');
    final next = DateTime.tryParse(prefs.getString(_nextKey) ?? '');
    _status = _status.copyWith(
      scheduledThrough: coverage,
      nextNotification: next,
    );
    notifyListeners();
  }

  Future<void> _saveMetadata(DateTime? coverage, DateTime? next) async {
    final prefs = await SharedPreferences.getInstance();
    if (coverage == null) {
      await prefs.remove(_coverageKey);
    } else {
      await prefs.setString(_coverageKey, coverage.toIso8601String());
    }
    if (next == null) {
      await prefs.remove(_nextKey);
    } else {
      await prefs.setString(_nextKey, next.toIso8601String());
    }
  }

  @visibleForTesting
  static int notificationId(DateTime date, PrayerName name) {
    final datePart = date.year * 10000 + date.month * 100 + date.day;
    return datePart * 10 + name.index;
  }

  String _dateValue(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _titleForLocale(String locale, PrayerName name) {
    final prayer = _prayerName(locale, name);
    return switch (locale) {
      'ar' => 'صلاة $prayer',
      'pl' => 'Modlitwa $prayer',
      _ => '$prayer prayer',
    };
  }

  String _bodyForLocale(String locale) {
    return switch (locale) {
      'ar' => 'حان وقت الصلاة • CKI Katowice',
      'pl' => 'Nadszedł czas modlitwy • CKI Katowice',
      _ => 'It’s time to pray • CKI Katowice',
    };
  }

  String _prayerName(String locale, PrayerName name) {
    return switch (locale) {
      'ar' => switch (name) {
        PrayerName.fajr => 'الفجر',
        PrayerName.sunrise => 'الشروق',
        PrayerName.dhuhr => 'الظهر',
        PrayerName.asr => 'العصر',
        PrayerName.maghrib => 'المغرب',
        PrayerName.isha => 'العشاء',
        PrayerName.jumuah => 'الجمعة',
      },
      'pl' => switch (name) {
        PrayerName.fajr => 'Fadżr',
        PrayerName.sunrise => 'Wschód słońca',
        PrayerName.dhuhr => 'Dhuhr',
        PrayerName.asr => 'Asr',
        PrayerName.maghrib => 'Maghrib',
        PrayerName.isha => 'Isza',
        PrayerName.jumuah => 'Dżumu\'a',
      },
      _ =>
        name == PrayerName.jumuah
            ? 'Jumu\'ah'
            : name.name[0].toUpperCase() + name.name.substring(1),
    };
  }

  void _setStatus(PrayerNotificationStatus value) {
    _status = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
