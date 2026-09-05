import 'dart:async';
import 'dart:isolate';

import 'package:ckikatowice/data/notifications/background_prayers.dart';
import 'package:ckikatowice/data/notifications/prayer_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:ckikatowice/data/notifications/schedule_lock.dart';
import 'package:ckikatowice/data/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native notification plugin retains and cancels a scheduled request',
    (tester) async {
      await tester.runAsync(() async {
        final gateway = NotificationService();
        await gateway.init();
        if (gateway.isIOS) {
          await FlutterLocalNotificationsPlugin()
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()!
              .requestPermissions(alert: true, sound: true, provisional: true);
        }
        const id = 9007;
        try {
          await gateway.schedule(
            id: id,
            when: tz.TZDateTime.now(
              gateway.prayerLocation,
            ).add(const Duration(days: 1)),
            title: 'Plugin integration check',
            body: 'Temporary test request',
            payload: 'integration-test',
            exact: false,
          );
          var registered = false;
          for (var i = 0; i < 10; i++) {
            registered = (await gateway.pendingRequests()).any(
              (p) => p.id == id,
            );
            if (registered) break;
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
          expect(registered, true);
        } finally {
          await gateway.cancel(id);
        }
        expect((await gateway.pendingRequests()).any((p) => p.id == id), false);
      });
    },
  );

  testWidgets(
    'SQLite lock serializes separate Dart isolates using native plugin',
    (tester) async {
      await tester.runAsync(() async {
        final token = RootIsolateToken.instance!;
        final acquired = Completer<void>();
        final release = Completer<void>();
        var finishedAt = 0;
        final first = const DatabaseScheduleLock(name: 'integration_lock').run(
          () async {
            acquired.complete();
            await release.future;
            finishedAt = DateTime.now().millisecondsSinceEpoch;
          },
        );
        unawaited(
          first.catchError((Object error) {
            if (!acquired.isCompleted) acquired.completeError(error);
          }),
        );
        await acquired.future;
        try {
          final second = _acquireInOtherIsolate(token);
          await Future<void>.delayed(const Duration(milliseconds: 500));
          release.complete();
          await first;
          expect(await second, greaterThanOrEqualTo(finishedAt));
        } finally {
          if (!release.isCompleted) release.complete();
          await first;
        }
      });
    },
  );

  testWidgets(
    'Workmanager registers and cancels the configured platform task',
    (tester) async {
      await tester.runAsync(() async {
        try {
          await BackgroundPrayers.configure(true);
        } finally {
          await BackgroundPrayers.configure(false);
        }
      });
    },
  );

  testWidgets('native Workmanager callback executes the shared scheduler', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final original = prefs.getStringList('enabled_prayers');
      await prefs.setStringList('enabled_prayers', []);
      await prefs.remove(PrayerScheduler.metadataKey);
      try {
        await BackgroundPrayers.configure(false);
        await Workmanager().registerOneOffTask(
          'integration-prayer-refresh',
          BackgroundPrayers.taskName,
        );
        final deadline = DateTime.now().add(const Duration(seconds: 15));
        do {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          await prefs.reload();
        } while (!prefs.containsKey(PrayerScheduler.metadataKey) &&
            DateTime.now().isBefore(deadline));
        expect(prefs.containsKey(PrayerScheduler.metadataKey), true);
      } finally {
        await Workmanager().cancelByUniqueName('integration-prayer-refresh');
        if (original == null) {
          await prefs.remove('enabled_prayers');
        } else {
          await prefs.setStringList('enabled_prayers', original);
        }
      }
    });
  });
}

Future<int> _acquireInOtherIsolate(RootIsolateToken token) =>
    Isolate.run(() async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      return const DatabaseScheduleLock(
        name: 'integration_lock',
      ).run(() async => DateTime.now().millisecondsSinceEpoch);
    });
