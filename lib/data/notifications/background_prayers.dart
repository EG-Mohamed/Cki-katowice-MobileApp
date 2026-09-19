import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../api/api_client.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import 'notification_status.dart';
import 'prayer_scheduler.dart';

@pragma('vm:entry-point')
void prayerBackgroundDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != BackgroundPrayers.taskName &&
        task != Workmanager.iOSBackgroundTask) {
      return true;
    }
    final api = ApiClient();
    try {
      // The background isolate has no app state; read the locale the
      // foreground app persisted so the Accept-locale header (and, via the
      // scheduler, notification text) matches what the user actually sees.
      final prefs = await SharedPreferences.getInstance();
      final storedLocale = prefs.getString('app_locale');
      if (['en', 'pl', 'ar'].contains(storedLocale)) {
        api.locale = storedLocale!;
      }
      final result = await PrayerScheduler(
        prayerService: ApiPrayerService(api),
        gateway: NotificationService(),
      ).synchronize();
      final success = result.syncState != PrayerNotificationSyncState.failed;
      await prefs.setString(
        _lastRunKey,
        success ? 'ok' : (result.lastError ?? 'failed'),
      );
      return success;
    } catch (error) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastRunKey, error.toString());
      } catch (_) {}
      return false;
    } finally {
      api.close();
    }
  });
}

const _lastRunKey = 'prayer_background_last_result';

class BackgroundPrayers {
  static const taskName = 'pl.ckikatowice.app.prayerRefresh';
  static Future<void>? _initializing;
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> configure(bool enabled) async {
    if (!supported) return;
    try {
      await (_initializing ??= Workmanager().initialize(
        prayerBackgroundDispatcher,
      ));
    } catch (_) {
      _initializing = null;
      rethrow;
    }
    if (!enabled) {
      await Workmanager().cancelByUniqueName(taskName);
      return;
    }
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      // The Android alarm horizon is now ~29 days, so this worker is a
      // top-up rather than the only thing keeping the schedule alive; the
      // in-app midnight/resume resyncs and the coverage reminder are the
      // other two legs of the same repair strategy.
      frequency: const Duration(hours: 12),
      initialDelay: const Duration(hours: 12),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }
}
