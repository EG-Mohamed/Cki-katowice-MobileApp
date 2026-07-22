// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appName => 'CKI Katowice';

  @override
  String get mosqueName => 'Islamskie Centrum Kulturalne Katowice';

  @override
  String get navHome => 'Główna';

  @override
  String get navQibla => 'Kibla';

  @override
  String get navRadio => 'Radio';

  @override
  String get navQuran => 'Koran';

  @override
  String get navNews => 'Aktualności';

  @override
  String get navMore => 'Więcej';

  @override
  String get greeting => 'Assalamu alejkum';

  @override
  String get nextPrayer => 'Następna modlitwa';

  @override
  String timeRemaining(Object time) {
    return 'za $time';
  }

  @override
  String get prayerNow => 'Już czas';

  @override
  String get fajr => 'Fadżr';

  @override
  String get sunrise => 'Wschód słońca';

  @override
  String get dhuhr => 'Zuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isza';

  @override
  String get jumuah => 'Dżumu\'a';

  @override
  String get todaySchedule => 'Dzisiejszy plan';

  @override
  String get previousDay => 'Poprzedni dzień';

  @override
  String get nextDay => 'Następny dzień';

  @override
  String get quickActions => 'Odkrywaj';

  @override
  String get qiblaDirection => 'Kierunek kibli';

  @override
  String get quranReader => 'Święty Koran';

  @override
  String get newsAnnouncements => 'Aktualności';

  @override
  String get khutbaTitle => 'Piątkowa chutba';

  @override
  String get qiblaHeading => 'Zwróć się ku kibli';

  @override
  String get qiblaInstruction =>
      'Trzymaj telefon poziomo i obracaj, aż znacznik wskaże Kaabę.';

  @override
  String get qiblaAligned => 'Jesteś zwrócony ku kibli';

  @override
  String qiblaDistance(Object km) {
    return '$km km do Kaaby';
  }

  @override
  String get qiblaPermission =>
      'Aby znaleźć kiblę, potrzebny jest dostęp do lokalizacji i czujników.';

  @override
  String get grantAccess => 'Zezwól na dostęp';

  @override
  String get calibrateHint =>
      'Poruszaj telefonem ruchem ósemki, aby skalibrować kompas.';

  @override
  String get surahs => 'Sury';

  @override
  String verses(Object count) {
    return '$count wersetów';
  }

  @override
  String get translation => 'Tłumaczenie';

  @override
  String get fontSize => 'Rozmiar czcionki';

  @override
  String get listenQuran => 'Słuchaj sury';

  @override
  String get stopListening => 'Zatrzymaj słuchanie';

  @override
  String get readMore => 'Czytaj dalej';

  @override
  String get searchNews => 'Szukaj aktualności';

  @override
  String get allCategories => 'Wszystkie';

  @override
  String get upcoming => 'Nadchodzące';

  @override
  String get past => 'Minione';

  @override
  String khatib(Object name) {
    return 'Wygłoszona przez $name';
  }

  @override
  String get settings => 'Ustawienia';

  @override
  String get language => 'Język';

  @override
  String get notifications => 'Powiadomienia';

  @override
  String get prayerNotifications => 'Przypomnienia o modlitwie';

  @override
  String get prayerNotificationsDesc =>
      'Automatycznie wysyłane, gdy odliczanie do modlitwy osiągnie zero.';

  @override
  String get enableAll => 'Wszystkie modlitwy';

  @override
  String get about => 'O aplikacji';

  @override
  String get aboutBody =>
      'Aplikacja dla społeczności CKI Katowice — czasy modlitw, kibla, Święty Koran, aktualności i piątkowa chutba.';

  @override
  String get english => 'English';

  @override
  String get polish => 'Polski';

  @override
  String get arabic => 'العربية';

  @override
  String get loading => 'Ładowanie…';

  @override
  String get prayerTimesUnavailable => 'Godziny modlitw są niedostępne.';

  @override
  String get emptyNews => 'Brak ogłoszeń.';

  @override
  String get emptyKhutba => 'Brak opublikowanej chutby.';

  @override
  String get quranUnavailable => 'Treść Koranu jest niedostępna.';

  @override
  String notificationBody(Object prayer) {
    return 'Nadszedł czas modlitwy $prayer.';
  }

  @override
  String get notificationTitle => 'Czas na modlitwę';

  @override
  String get adhanOn => 'Azan wł.';

  @override
  String get adhanOff => 'Azan wył.';

  @override
  String get reciters => 'Recytatorzy';

  @override
  String get reciter => 'Recytator';

  @override
  String get selectReciter => 'Wybierz recytatora';

  @override
  String get changeReciter => 'Zmień recytatora';

  @override
  String get riwayah => 'Rywaja';

  @override
  String get nowPlaying => 'Teraz odtwarzane';

  @override
  String get radios => 'Stacje radiowe';

  @override
  String get playSurah => 'Odtwórz surę';

  @override
  String get pause => 'Pauza';

  @override
  String get resume => 'Wznów';

  @override
  String get nextSurah => 'Następna';

  @override
  String get previousSurah => 'Poprzednia';

  @override
  String get readText => 'Czytaj tekst';

  @override
  String get autoplayNext => 'Automatycznie odtwarzaj następną surę';

  @override
  String get recitersUnavailable => 'Recytatorzy są niedostępni.';

  @override
  String get noReciterSelected =>
      'Wybierz recytatora, aby rozpocząć słuchanie.';

  @override
  String get searchReciters => 'Szukaj recytatorów';

  @override
  String get announcementDismiss => 'Odrzuć';

  @override
  String get announcementDetails => 'Szczegóły';

  @override
  String get announcementUrgent => 'Pilne';

  @override
  String get announcementMaintenance => 'Konserwacja';

  @override
  String get announcementGeneral => 'Ogłoszenie';

  @override
  String get appearance => 'Wygląd';

  @override
  String get darkMode => 'Tryb ciemny';

  @override
  String get darkModeDesc => 'Używaj ciemnego motywu w całej aplikacji.';

  @override
  String get openInMaps => 'Otwórz w Mapach';

  @override
  String get searchSurah => 'Szukaj sury';

  @override
  String get noResults => 'Brak wyników.';

  @override
  String get radioLive => 'Radia Koranu na żywo';

  @override
  String get searchRadios => 'Szukaj stacji';

  @override
  String get testNotification => 'Wyślij powiadomienie testowe';

  @override
  String get testNotificationBody =>
      'Tak będą wyglądać przypomnienia o modlitwie.';

  @override
  String get notificationPermissionDenied =>
      'Wymagane jest pozwolenie na powiadomienia. Włącz je w ustawieniach systemu.';

  @override
  String get exactAlarmHint =>
      'Aby przypomnienia były punktualne, zezwól tej aplikacji na \'Alarmy i przypomnienia\' w ustawieniach systemu.';

  @override
  String get notificationSyncing => 'Aktualizowanie przypomnień o modlitwie…';

  @override
  String notificationScheduled(Object count, Object date) {
    return 'Zaplanowano $count przypomnień do $date.';
  }

  @override
  String get notificationScheduleFailed =>
      'Nie udało się zaktualizować przypomnień. Istniejące przypomnienia zachowano.';

  @override
  String get notificationDelayedHint =>
      'Przypomnienia są włączone, ale Android może je opóźnić do czasu przyznania dostępu do dokładnych alarmów.';

  @override
  String get testNotificationScheduled =>
      'Test zaplanowany. Zablokuj teraz ekran; powiadomienie pojawi się za około 15 sekund.';

  @override
  String get openSystemSettings => 'Otwórz ustawienia systemowe';
}
