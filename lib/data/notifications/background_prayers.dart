import 'package:flutter/foundation.dart';
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
      final result = await PrayerScheduler(
        prayerService: ApiPrayerService(api),
        gateway: NotificationService(),
      ).synchronize(force: true);
      return result.syncState != PrayerNotificationSyncState.failed;
    } catch (error, stack) {
      debugPrint('Prayer background refresh failed: $error\n$stack');
      return false;
    } finally {
      api.close();
    }
  });
}

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
      frequency: const Duration(hours: 12),
      initialDelay: const Duration(hours: 12),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }
}
