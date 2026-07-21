import '../../data/models/prayer.dart';
import '../localization/arb/app_localizations.dart';

String prayerLabel(AppLocalizations l10n, PrayerName name) {
  switch (name) {
    case PrayerName.fajr:
      return l10n.fajr;
    case PrayerName.sunrise:
      return l10n.sunrise;
    case PrayerName.dhuhr:
      return l10n.dhuhr;
    case PrayerName.asr:
      return l10n.asr;
    case PrayerName.maghrib:
      return l10n.maghrib;
    case PrayerName.isha:
      return l10n.isha;
  }
}
