import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const String prayerZone = 'Europe/Warsaw';

bool _initialized = false;

void initPrayerTimeZones() {
  if (_initialized) return;
  tz_data.initializeTimeZones();
  _initialized = true;
}

tz.Location get prayerLocation {
  initPrayerTimeZones();
  return tz.getLocation(prayerZone);
}

tz.TZDateTime prayerNow() => tz.TZDateTime.now(prayerLocation);

tz.TZDateTime prayerInstant(DateTime date, TimeOfDay time) {
  return tz.TZDateTime(
    prayerLocation,
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}

DateTime prayerToday() {
  final now = prayerNow();
  return DateTime(now.year, now.month, now.day);
}