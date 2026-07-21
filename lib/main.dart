import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/api/api_client.dart';
import 'data/audio/audio_handler.dart';
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
import 'state/quran_player_controller.dart';
import 'state/settings_controller.dart';
import 'state/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final localeController = LocaleController(apiClient);
  final notificationController = NotificationController();
  final themeController = ThemeController();
  await localeController.load();
  await notificationController.load();
  await themeController.load();

  final prayerController = PrayerController(ApiPrayerService(apiClient));
  unawaited(prayerController.load());

  final announcementController =
      AnnouncementController(ApiAnnouncementService(apiClient));
  await announcementController.loadDismissed();
  unawaited(announcementController.load());

  final audioHandler = await AudioService.init(
    builder: () => QuranAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'pl.ckikatowice.audio',
      androidNotificationChannelName: 'Quran playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  final quranPlayerController = QuranPlayerController(audioHandler)
    ..bindStreams();
  await quranPlayerController.load();

  final settingsController = SettingsController(ApiSettingsService(apiClient));
  unawaited(settingsController.load());

  localeController.addListener(() {
    announcementController.load();
    settingsController.load();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeController),
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: notificationController),
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
        Provider<SettingsService>(
          create: (_) => ApiSettingsService(apiClient),
        ),
        Provider<QiblaService>(create: (_) => QiblaService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: const CkiApp(),
    ),
  );
}
