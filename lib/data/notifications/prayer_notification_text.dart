import 'package:flutter/material.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/utils/prayer_labels.dart';
import '../models/prayer.dart';

String prayerNotificationTitle(String locale, PrayerName name) {
  final l10n = lookupAppLocalizations(Locale(locale));
  return l10n.notificationTitle;
}

String prayerNotificationBody(String locale, PrayerName name) {
  final l10n = lookupAppLocalizations(Locale(locale));
  return l10n.notificationBody(prayerLabel(l10n, name));
}
