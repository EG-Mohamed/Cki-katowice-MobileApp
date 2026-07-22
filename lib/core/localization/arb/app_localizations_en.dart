// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CKI Katowice';

  @override
  String get mosqueName => 'Islamic Cultural Centre Katowice';

  @override
  String get navHome => 'Home';

  @override
  String get navQibla => 'Qibla';

  @override
  String get navRadio => 'Radio';

  @override
  String get navQuran => 'Quran';

  @override
  String get navNews => 'News';

  @override
  String get navMore => 'More';

  @override
  String get greeting => 'Assalamu Alaikum';

  @override
  String get nextPrayer => 'Next prayer';

  @override
  String timeRemaining(Object time) {
    return 'in $time';
  }

  @override
  String get prayerNow => 'It\'s time';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get jumuah => 'Jumu\'ah';

  @override
  String get todaySchedule => 'Today\'s schedule';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get quickActions => 'Explore';

  @override
  String get qiblaDirection => 'Qibla';

  @override
  String get quranReader => 'Holy Quran';

  @override
  String get newsAnnouncements => 'News';

  @override
  String get khutbaTitle => 'Khutba';

  @override
  String get qiblaHeading => 'Face the Qibla';

  @override
  String get qiblaInstruction =>
      'Hold your phone flat and turn until the marker aligns with the Kaaba.';

  @override
  String get qiblaAligned => 'You are facing the Qibla';

  @override
  String qiblaDistance(Object km) {
    return '$km km to the Kaaba';
  }

  @override
  String get qiblaPermission =>
      'Location & sensor access is needed to find the Qibla.';

  @override
  String get grantAccess => 'Grant access';

  @override
  String get calibrateHint =>
      'Move your phone in a figure-8 to calibrate the compass.';

  @override
  String get surahs => 'Surahs';

  @override
  String verses(Object count) {
    return '$count verses';
  }

  @override
  String get translation => 'Translation';

  @override
  String get fontSize => 'Font size';

  @override
  String get listenQuran => 'Listen to surah';

  @override
  String get stopListening => 'Stop listening';

  @override
  String get readMore => 'Read more';

  @override
  String get searchNews => 'Search news';

  @override
  String get allCategories => 'All';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get past => 'Past';

  @override
  String khatib(Object name) {
    return 'Delivered by $name';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get prayerNotifications => 'Prayer reminders';

  @override
  String get prayerNotificationsDesc =>
      'Automatically delivered when each prayer countdown reaches zero.';

  @override
  String get enableAll => 'All prayers';

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'An app for the CKI Katowice community — prayer times, Qibla, the Holy Quran, news and the Friday Khutba.';

  @override
  String get english => 'English';

  @override
  String get polish => 'Polski';

  @override
  String get arabic => 'العربية';

  @override
  String get loading => 'Loading…';

  @override
  String get prayerTimesUnavailable => 'Prayer times are unavailable.';

  @override
  String get emptyNews => 'No announcements yet.';

  @override
  String get emptyKhutba => 'No Khutba published yet.';

  @override
  String get quranUnavailable => 'Quran content is unavailable.';

  @override
  String notificationBody(Object prayer) {
    return 'It is time for $prayer prayer.';
  }

  @override
  String get notificationTitle => 'Time for prayer';

  @override
  String get adhanOn => 'Adhan on';

  @override
  String get adhanOff => 'Adhan off';

  @override
  String get reciters => 'Reciters';

  @override
  String get reciter => 'Reciter';

  @override
  String get selectReciter => 'Select a reciter';

  @override
  String get changeReciter => 'Change reciter';

  @override
  String get riwayah => 'Narration';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get radios => 'Radio stations';

  @override
  String get playSurah => 'Play surah';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get nextSurah => 'Next';

  @override
  String get previousSurah => 'Previous';

  @override
  String get readText => 'Read text';

  @override
  String get autoplayNext => 'Autoplay next surah';

  @override
  String get recitersUnavailable => 'Reciters are unavailable.';

  @override
  String get noReciterSelected => 'Choose a reciter to start listening.';

  @override
  String get searchReciters => 'Search reciters';

  @override
  String get announcementDismiss => 'Dismiss';

  @override
  String get announcementDetails => 'Details';

  @override
  String get announcementUrgent => 'Urgent';

  @override
  String get announcementMaintenance => 'Maintenance';

  @override
  String get announcementGeneral => 'Announcement';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeDesc => 'Use a dark theme across the app.';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String get searchSurah => 'Search surah';

  @override
  String get noResults => 'No results found.';

  @override
  String get radioLive => 'Live Quran radio stations';

  @override
  String get searchRadios => 'Search stations';

  @override
  String get testNotification => 'Send a test notification';

  @override
  String get testNotificationBody =>
      'This is how prayer reminders will appear.';

  @override
  String get notificationPermissionDenied =>
      'Notification permission is required. Please enable it in system settings.';

  @override
  String get exactAlarmHint =>
      'For exact on-time reminders, allow \'Alarms & reminders\' for this app in system settings.';

  @override
  String get notificationSyncing => 'Updating prayer reminders…';

  @override
  String notificationScheduled(Object count, Object date) {
    return '$count reminders scheduled through $date.';
  }

  @override
  String get notificationScheduleFailed =>
      'Prayer reminders could not be updated. Existing reminders were kept.';

  @override
  String get notificationDelayedHint =>
      'Reminders are enabled, but Android may delay them until exact alarm access is granted.';

  @override
  String get testNotificationScheduled =>
      'Test scheduled. Lock the screen now; it will arrive in about 15 seconds.';

  @override
  String get openSystemSettings => 'Open system settings';
}
