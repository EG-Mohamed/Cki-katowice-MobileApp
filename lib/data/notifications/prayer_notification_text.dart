import '../models/prayer.dart';

String prayerNotificationTitle(String locale, PrayerName name) {
  final prayer = _prayerName(locale, name);
  return switch (locale) {
    'ar' => 'صلاة $prayer',
    'pl' => 'Modlitwa $prayer',
    _ => '$prayer prayer',
  };
}

String prayerNotificationBody(String locale) {
  return switch (locale) {
    'ar' => 'حان وقت الصلاة • CKI Katowice',
    'pl' => 'Nadszedł czas modlitwy • CKI Katowice',
    _ => 'It’s time to pray • CKI Katowice',
  };
}

String _prayerName(String locale, PrayerName name) {
  return switch (locale) {
    'ar' => switch (name) {
      PrayerName.fajr => 'الفجر',
      PrayerName.sunrise => 'الشروق',
      PrayerName.dhuhr => 'الظهر',
      PrayerName.asr => 'العصر',
      PrayerName.maghrib => 'المغرب',
      PrayerName.isha => 'العشاء',
      PrayerName.jumuah => 'الجمعة',
    },
    'pl' => switch (name) {
      PrayerName.fajr => 'Fadżr',
      PrayerName.sunrise => 'Wschód słońca',
      PrayerName.dhuhr => 'Dhuhr',
      PrayerName.asr => 'Asr',
      PrayerName.maghrib => 'Maghrib',
      PrayerName.isha => 'Isza',
      PrayerName.jumuah => 'Dżumu\'a',
    },
    _ =>
      name == PrayerName.jumuah
          ? 'Jumu\'ah'
          : name.name[0].toUpperCase() + name.name.substring(1),
  };
}
