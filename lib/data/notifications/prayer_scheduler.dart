import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/localization/arb/app_localizations.dart';
import '../models/prayer.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../../state/notification_controller.dart';
import 'notification_status.dart';
import 'prayer_notification_text.dart';
import 'schedule_lock.dart';

/// No lifecycle observers, permission dialogs, UI timers or audio players here.
/// Both the foreground coordinator and Workmanager call this scheduler.
class PrayerScheduler {
  PrayerScheduler({
    required this.prayerService,
    required this.gateway,
    this.lock = const DatabaseScheduleLock(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PrayerService prayerService;
  final NotificationGateway gateway;
  final ScheduleLock lock;
  final DateTime Function() _now;
  static const metadataKey = 'prayer_schedule_status_v2';
  static const reminderId = 9998;

  Future<PrayerNotificationStatus> synchronize({bool force = false}) async {
    await gateway.init();
    // Fetch outside the lock so slow/offline networking cannot block a mute.
    // Preferences are read again under the lock before any notification writes.
    final hintPrefs = await SharedPreferences.getInstance();
    await hintPrefs.reload();
    List<DailyPrayers> fetchedDays = const [];
    Object? fetchError;
    if (hintPrefs.getStringList(NotificationController.storageKey)?.isEmpty !=
            true &&
        await gateway.notificationsEnabled()) {
      final instant = tz.TZDateTime.from(_now(), gateway.prayerLocation);
      final from = DateTime(instant.year, instant.month, instant.day);
      final to = DateTime(
        from.year,
        from.month,
        from.day + (gateway.isIOS ? 11 : 6),
      );
      try {
        fetchedDays = await prayerService.range(from: from, to: to);
      } catch (e) {
        fetchError = e;
      }
    }
    return lock.run(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final stored = prefs.getStringList(NotificationController.storageKey);
      final enabled = stored == null
          ? NotificationController.notifiable.toSet()
          : NotificationController.notifiable
                .where((p) => stored.contains(p.name))
                .toSet();
      final storedLocale = prefs.getString('app_locale');
      final locale = ['en', 'pl', 'ar'].contains(storedLocale)
          ? storedLocale!
          : 'en';
      final now = tz.TZDateTime.from(_now(), gateway.prayerLocation);
      final horizon = DateTime(
        now.year,
        now.month,
        now.day + (gateway.isIOS ? 11 : 6),
      );
      var exact = await gateway.canScheduleExactAlarms();
      var pending = await gateway.pendingRequests();
      DateTime? lastRefresh;
      try {
        final metadata =
            jsonDecode(prefs.getString(metadataKey) ?? '{}')
                as Map<String, dynamic>;
        lastRefresh = DateTime.tryParse(
          metadata['lastRefresh'] as String? ?? '',
        );
      } catch (_) {}
      DateTime? coverage;
      String? error;
      final permission = await gateway.notificationsEnabled();

      try {
        // Muting and trimming the previous 30-day Android window must also
        // work offline and after permission has been revoked.
        for (final request in pending.where(_managed)) {
          final name = _prayerOf(request);
          if (enabled.isEmpty ||
              (name != null && !enabled.contains(name)) ||
              (_instantOf(request)?.isBefore(now) ?? false) ||
              (_dateOf(request)?.compareTo(_date(now)) ?? 0) < 0 ||
              (gateway.isAndroid &&
                  (_dateOf(request)?.compareTo(_date(horizon)) ?? 0) > 0)) {
            await gateway.cancel(request.id);
          }
        }
        if (enabled.isEmpty) {
          await gateway.cancel(reminderId);
        } else if (permission) {
          final from = DateTime(now.year, now.month, now.day);
          final to = DateTime(
            from.year,
            from.month,
            from.day + (gateway.isIOS ? 11 : 6),
          );
          if (fetchError != null) throw fetchError;
          final byDate = {for (final day in fetchedDays) _date(day.date): day};
          if (byDate.isEmpty) throw StateError('No prayer times available');
          pending = await gateway.pendingRequests();
          final existing = {for (final p in pending) p.id: p};
          final unrelated = pending
              .where(
                (p) =>
                    !_managed(p) &&
                    p.id != reminderId &&
                    p.id != NotificationService.testNotificationId,
              )
              .length;
          // Two slots reserved for the coverage reminder and lock-screen test.
          final capacity = gateway.isIOS ? (62 - unrelated).clamp(0, 60) : 500;
          final desired = <int, _Alarm>{};
          var contiguous = true;
          DateTime? completeThrough;
          for (
            var date = from;
            !date.isAfter(to);
            date = DateTime(date.year, date.month, date.day + 1)
          ) {
            final day = byDate[_date(date)];
            if (day == null) {
              contiguous = false;
              error ??= 'Prayer timetable has missing dates';
              continue;
            }
            final slots =
                day.notifiable.where((s) => enabled.contains(s.name)).toList()
                  ..sort(
                    (a, b) => (a.time.hour * 60 + a.time.minute).compareTo(
                      b.time.hour * 60 + b.time.minute,
                    ),
                  );
            var complete = true;
            for (final slot in slots) {
              final when = tz.TZDateTime(
                gateway.prayerLocation,
                date.year,
                date.month,
                date.day,
                slot.time.hour,
                slot.time.minute,
              );
              if (!when.isAfter(now)) continue;
              if (desired.length >= capacity) {
                complete = false;
                break;
              }
              final id = notificationId(date, slot.name);
              desired[id] = _Alarm(id, when, slot.name, locale, exact);
            }
            if (!complete) contiguous = false;
            if (contiguous) completeThrough = date;
          }

          // Make space first on iOS without discarding valid future coverage when
          // the API returns only a partial timetable.
          for (final p in pending.where(_managed)) {
            final date = _dateOf(p);
            if (!desired.containsKey(p.id) &&
                date != null &&
                byDate.containsKey(date)) {
              await gateway.cancel(p.id);
            }
          }
          var count = (await gateway.pendingRequests()).where(_managed).length;
          for (final alarm in desired.values) {
            // Android's pending API is plugin persistence, not an AlarmManager
            // query. Explicit repairs, launch and worker runs reapply alarms;
            // routine foreground refreshes only write changed or missing alarms.
            if (!(force && gateway.isAndroid) &&
                existing[alarm.id]?.payload == alarm.payload) {
              continue;
            }
            if (!existing.containsKey(alarm.id) && count >= capacity) {
              throw StateError('Notification capacity reached');
            }
            try {
              await _schedule(alarm);
            } catch (_) {
              // Exact access can be revoked between the capability check and call.
              if (!exact || await gateway.canScheduleExactAlarms()) rethrow;
              exact = false;
              throw StateError('Exact alarm access changed; refresh required');
            }
            if (!existing.containsKey(alarm.id)) count++;
          }
          final verified = {
            for (final p in await gateway.pendingRequests()) p.id: p,
          };
          if (desired.values.any((a) => verified[a.id]?.payload != a.payload)) {
            throw StateError('Notification registration could not be verified');
          }
          coverage = completeThrough;
          if (gateway.isIOS) {
            final l10n = lookupAppLocalizations(Locale(locale));
            final through = coverage;
            if (through != null) {
              final expires = tz.TZDateTime(
                gateway.prayerLocation,
                through.year,
                through.month,
                through.day + 1,
              );
              final reminder = expires.subtract(const Duration(hours: 24));
              final when = reminder.isAfter(now)
                  ? reminder
                  : now.add(const Duration(minutes: 1));
              final payload =
                  'coverage:${expires.toUtc().toIso8601String()}:$locale';
              if (verified[reminderId]?.payload != payload) {
                await gateway.schedule(
                  id: reminderId,
                  when: when,
                  title: l10n.notificationCoverageTitle,
                  body: l10n.notificationCoverageBody,
                  payload: payload,
                  exact: false,
                );
              }
            } else {
              await gateway.cancel(reminderId);
            }
          }
        }
      } catch (e) {
        error = e.toString();
      }
      pending = await gateway.pendingRequests();
      final future = pending
          .where(_managed)
          .where((p) => _instantOf(p)?.isAfter(now) ?? false)
          .toList();
      final times = future.map(_instantOf).whereType<DateTime>().toList()
        ..sort();
      final status = PrayerNotificationStatus(
        permission: permission
            ? PrayerNotificationPermission.granted
            : PrayerNotificationPermission.denied,
        exactAlarmAvailable: exact,
        syncState: error == null
            ? PrayerNotificationSyncState.ready
            : PrayerNotificationSyncState.failed,
        scheduledCount: future.length,
        scheduledThrough: coverage,
        nextNotification: times.isEmpty ? null : times.first,
        lastRefresh: error == null && permission ? now.toUtc() : lastRefresh,
        lastError: error,
      );
      await prefs.setString(
        metadataKey,
        jsonEncode({
          'coverage': coverage?.toIso8601String(),
          'next': status.nextNotification?.toIso8601String(),
          'lastRefresh': status.lastRefresh?.toIso8601String(),
          'error': error,
          'count': status.scheduledCount,
        }),
      );
      return status;
    });
  }

  Future<void> _schedule(_Alarm a) => gateway.schedule(
    id: a.id,
    when: a.when,
    title: prayerNotificationTitle(a.locale, a.name),
    body: prayerNotificationBody(a.locale),
    payload: a.payload,
    exact: a.exact,
  );

  static int notificationId(DateTime date, PrayerName name) =>
      (date.year * 10000 + date.month * 100 + date.day) * 10 + name.index;

  static bool _managed(PendingNotificationRequest p) =>
      p.payload?.startsWith(NotificationService.payloadPrefix) ?? false;
  static String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static String? _dateOf(PendingNotificationRequest p) {
    final parts = p.payload?.split('|').first.split(':');
    return parts != null && parts.length >= 3 ? parts[1] : null;
  }

  static PrayerName? _prayerOf(PendingNotificationRequest p) {
    final parts = p.payload?.split('|').first.split(':');
    if (parts == null || parts.length < 3) return null;
    for (final name in PrayerName.values) {
      if (name.name == parts[2]) return name;
    }
    return null;
  }

  static DateTime? _instantOf(PendingNotificationRequest p) {
    final parts = p.payload?.split('|');
    if (parts == null || parts.length < 2) return null;
    return DateTime.tryParse(parts[1]);
  }
}

class _Alarm {
  const _Alarm(this.id, this.when, this.name, this.locale, this.exact);
  final int id;
  final tz.TZDateTime when;
  final PrayerName name;
  final String locale;
  final bool exact;
  String get payload =>
      'prayer:${PrayerScheduler._date(when)}:${name.name}|${when.toUtc().toIso8601String()}|$exact|$locale|v3';
}
