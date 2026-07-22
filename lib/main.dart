import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/api/api_client.dart';
import 'data/audio/audio_handler.dart';
import 'data/models/prayer.dart';
import 'data/services/announcement_service.dart';
import 'data/services/khutba_service.dart';
import 'data/services/mp3quran_service.dart';
import 'data/services/news_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/prayer_service.dart';
import 'data/services/qibla_service.dart';
import 'data/services/quran_service.dart';
import 'data/services/settings_service.dart';
import 'state/announcement_controller.dart';
import 'state/locale_controller.dart';
import 'state/notification_controller.dart';
import 'state/prayer_controller.dart';
import 'state/prayer_notification_coordinator.dart';
import 'state/quran_player_controller.dart';
import 'shared/widgets/splash_gate.dart';
import 'state/settings_controller.dart';
import 'state/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final localeController = LocaleController(apiClient);
  final notificationController = NotificationController();
  final themeController = ThemeController();
  await Future.wait([
    localeController.load(),
    notificationController.load(),
    themeController.load(),
  ]);

  final prayerService = ApiPrayerService(apiClient);
  final prayerController = PrayerController(prayerService);
  final firstPrayerLoad = prayerController.load();

  final notificationService = NotificationService();
  final prayerNotificationCoordinator = PrayerNotificationCoordinator(
    preferences: notificationController,
    prayerService: prayerService,
    gateway: notificationService,
    localeCode: () => localeController.locale.languageCode,
  );
  prayerController.onPrayerDue = (day, slot) {
    unawaited(prayerNotificationCoordinator.showNow(day, slot));
    unawaited(prayerNotificationCoordinator.synchronize(force: true));
  };
  PrayerName? lastNextPrayer;
  prayerController.addListener(() {
    final next = prayerController.nextPrayer?.name;
    if (next != null && next != lastNextPrayer) {
      lastNextPrayer = next;
      unawaited(
        prayerNotificationCoordinator.synchronize(
          force: !prayerNotificationCoordinator.everSucceeded,
        ),
      );
    }
  });

  final announcementController = AnnouncementController(
    ApiAnnouncementService(apiClient),
  );
  final quranPlayerController = QuranPlayerController(
    () => AudioService.init(
      builder: () => QuranAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'pl.ckikatowice.audio',
        androidNotificationChannelName: 'Quran playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    ),
  );
  await Future.wait([
    announcementController.loadDismissed(),
    quranPlayerController.load(),
  ]);
  unawaited(announcementController.load());

  final settingsController = SettingsController(ApiSettingsService(apiClient));
  unawaited(settingsController.load());

  localeController.addListener(() {
    announcementController.load();
    settingsController.load();
    unawaited(prayerNotificationCoordinator.synchronize(force: true));
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeController),
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: notificationController),
        ChangeNotifierProvider.value(value: prayerNotificationCoordinator),
        ChangeNotifierProvider.value(value: prayerController),
        ChangeNotifierProvider.value(value: announcementController),
        ChangeNotifierProvider.value(value: quranPlayerController),
        ChangeNotifierProvider.value(value: settingsController),
        Provider<ApiClient>.value(value: apiClient),
        Provider<NewsService>(create: (_) => ApiNewsService(apiClient)),
        Provider<KhutbaService>(create: (_) => ApiKhutbaService(apiClient)),
        Provider<QuranService>(create: (_) => ApiQuranService()),
        Provider<Mp3QuranService>(create: (_) => ApiMp3QuranService()),
        Provider<AnnouncementService>(
          create: (_) => ApiAnnouncementService(apiClient),
        ),
        Provider<SettingsService>(create: (_) => ApiSettingsService(apiClient)),
        Provider<QiblaService>(create: (_) => QiblaService()),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: SplashGate(ready: firstPrayerLoad, child: const CkiApp()),
    ),
  );
  unawaited(prayerNotificationCoordinator.start());
}
