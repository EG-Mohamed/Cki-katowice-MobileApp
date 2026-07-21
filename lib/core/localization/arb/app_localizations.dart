import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'CKI Katowice'**
  String get appName;

  /// No description provided for @mosqueName.
  ///
  /// In en, this message translates to:
  /// **'Islamic Cultural Centre Katowice'**
  String get mosqueName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navQibla.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get navQibla;

  /// No description provided for @navQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get navQuran;

  /// No description provided for @navNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get navNews;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Assalamu Alaikum'**
  String get greeting;

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get nextPrayer;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String timeRemaining(Object time);

  /// No description provided for @prayerNow.
  ///
  /// In en, this message translates to:
  /// **'It\'s time'**
  String get prayerNow;

  /// No description provided for @fajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @dhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;

  /// No description provided for @jumuah.
  ///
  /// In en, this message translates to:
  /// **'Jumu\'ah'**
  String get jumuah;

  /// No description provided for @todaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s schedule'**
  String get todaySchedule;

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get quickActions;

  /// No description provided for @qiblaDirection.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qiblaDirection;

  /// No description provided for @quranReader.
  ///
  /// In en, this message translates to:
  /// **'Holy Quran'**
  String get quranReader;

  /// No description provided for @newsAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get newsAnnouncements;

  /// No description provided for @khutbaTitle.
  ///
  /// In en, this message translates to:
  /// **'Khutba'**
  String get khutbaTitle;

  /// No description provided for @qiblaHeading.
  ///
  /// In en, this message translates to:
  /// **'Face the Qibla'**
  String get qiblaHeading;

  /// No description provided for @qiblaInstruction.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone flat and turn until the marker aligns with the Kaaba.'**
  String get qiblaInstruction;

  /// No description provided for @qiblaAligned.
  ///
  /// In en, this message translates to:
  /// **'You are facing the Qibla'**
  String get qiblaAligned;

  /// No description provided for @qiblaDistance.
  ///
  /// In en, this message translates to:
  /// **'{km} km to the Kaaba'**
  String qiblaDistance(Object km);

  /// No description provided for @qiblaPermission.
  ///
  /// In en, this message translates to:
  /// **'Location & sensor access is needed to find the Qibla.'**
  String get qiblaPermission;

  /// No description provided for @grantAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get grantAccess;

  /// No description provided for @calibrateHint.
  ///
  /// In en, this message translates to:
  /// **'Move your phone in a figure-8 to calibrate the compass.'**
  String get calibrateHint;

  /// No description provided for @surahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get surahs;

  /// No description provided for @verses.
  ///
  /// In en, this message translates to:
  /// **'{count} verses'**
  String verses(Object count);

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @listenQuran.
  ///
  /// In en, this message translates to:
  /// **'Listen to surah'**
  String get listenQuran;

  /// No description provided for @stopListening.
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get stopListening;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @searchNews.
  ///
  /// In en, this message translates to:
  /// **'Search news'**
  String get searchNews;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @khatib.
  ///
  /// In en, this message translates to:
  /// **'Delivered by {name}'**
  String khatib(Object name);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @prayerNotifications.
  ///
  /// In en, this message translates to:
  /// **'Prayer reminders'**
  String get prayerNotifications;

  /// No description provided for @prayerNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified at each prayer time.'**
  String get prayerNotificationsDesc;

  /// No description provided for @enableAll.
  ///
  /// In en, this message translates to:
  /// **'All prayers'**
  String get enableAll;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'An app for the CKI Katowice community — prayer times, Qibla, the Holy Quran, news and the Friday Khutba.'**
  String get aboutBody;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @polish.
  ///
  /// In en, this message translates to:
  /// **'Polski'**
  String get polish;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @prayerTimesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are unavailable.'**
  String get prayerTimesUnavailable;

  /// No description provided for @emptyNews.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet.'**
  String get emptyNews;

  /// No description provided for @emptyKhutba.
  ///
  /// In en, this message translates to:
  /// **'No Khutba published yet.'**
  String get emptyKhutba;

  /// No description provided for @quranUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Quran content is unavailable.'**
  String get quranUnavailable;

  /// No description provided for @notificationBody.
  ///
  /// In en, this message translates to:
  /// **'It is time for {prayer} prayer.'**
  String notificationBody(Object prayer);

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for prayer'**
  String get notificationTitle;

  /// No description provided for @adhanOn.
  ///
  /// In en, this message translates to:
  /// **'Adhan on'**
  String get adhanOn;

  /// No description provided for @adhanOff.
  ///
  /// In en, this message translates to:
  /// **'Adhan off'**
  String get adhanOff;

  /// No description provided for @reciters.
  ///
  /// In en, this message translates to:
  /// **'Reciters'**
  String get reciters;

  /// No description provided for @reciter.
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get reciter;

  /// No description provided for @selectReciter.
  ///
  /// In en, this message translates to:
  /// **'Select a reciter'**
  String get selectReciter;

  /// No description provided for @changeReciter.
  ///
  /// In en, this message translates to:
  /// **'Change reciter'**
  String get changeReciter;

  /// No description provided for @riwayah.
  ///
  /// In en, this message translates to:
  /// **'Narration'**
  String get riwayah;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @radios.
  ///
  /// In en, this message translates to:
  /// **'Radio stations'**
  String get radios;

  /// No description provided for @playSurah.
  ///
  /// In en, this message translates to:
  /// **'Play surah'**
  String get playSurah;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @nextSurah.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextSurah;

  /// No description provided for @previousSurah.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousSurah;

  /// No description provided for @readText.
  ///
  /// In en, this message translates to:
  /// **'Read text'**
  String get readText;

  /// No description provided for @autoplayNext.
  ///
  /// In en, this message translates to:
  /// **'Autoplay next surah'**
  String get autoplayNext;

  /// No description provided for @recitersUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reciters are unavailable.'**
  String get recitersUnavailable;

  /// No description provided for @noReciterSelected.
  ///
  /// In en, this message translates to:
  /// **'Choose a reciter to start listening.'**
  String get noReciterSelected;

  /// No description provided for @searchReciters.
  ///
  /// In en, this message translates to:
  /// **'Search reciters'**
  String get searchReciters;

  /// No description provided for @announcementDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get announcementDismiss;

  /// No description provided for @announcementDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get announcementDetails;

  /// No description provided for @announcementUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get announcementUrgent;

  /// No description provided for @announcementMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get announcementMaintenance;

  /// No description provided for @announcementGeneral.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcementGeneral;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @darkModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Use a dark theme across the app.'**
  String get darkModeDesc;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @searchSurah.
  ///
  /// In en, this message translates to:
  /// **'Search surah'**
  String get searchSurah;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResults;

  /// No description provided for @radioLive.
  ///
  /// In en, this message translates to:
  /// **'Live Quran radio stations'**
  String get radioLive;

  /// No description provided for @searchRadios.
  ///
  /// In en, this message translates to:
  /// **'Search stations'**
  String get searchRadios;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
