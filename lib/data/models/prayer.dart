import 'package:flutter/material.dart';

import '../../core/utils/prayer_time.dart' as prayer_time;

enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha, jumuah }

class PrayerSlot {
  const PrayerSlot({
    required this.name,
    required this.time,
    this.isNotifiable = true,
    this.iqamah,
  });

  final PrayerName name;
  final TimeOfDay time;
  final bool isNotifiable;
  final TimeOfDay? iqamah;

  /// A Warsaw-local instant for this slot on [day]. Prayer times are always
  /// meant in the mosque's timezone, regardless of the device's own zone.
  DateTime dateTimeOn(DateTime day) {
    return prayer_time.prayerInstant(day, time);
  }
}

class DailyPrayers {
  const DailyPrayers({required this.date, required this.slots});

  factory DailyPrayers.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    if (rawDate is! String || rawDate.length < 10) {
      throw const FormatException('Missing or invalid prayer date');
    }
    final date = DateTime.parse(rawDate.substring(0, 10));
    final jummah = json['jummah'];
    final isFriday = date.weekday == DateTime.friday;
    final hasJumuah =
        isFriday && jummah is Map<String, dynamic> && jummah['adhan'] != null;
    return DailyPrayers(
      date: date,
      slots: [
        PrayerSlot(
          name: PrayerName.fajr,
          time: _timeFromNested(json['fajr']),
          iqamah: _timeFromNestedOrNull(json['fajr'], 'iqamah'),
        ),
        PrayerSlot(
          name: PrayerName.sunrise,
          time: _timeFromValue(json['sunrise']),
          isNotifiable: false,
        ),
        // Dhuhr is always present: on Friday it is the base congregational
        // prayer time regardless of whether a separate Jumu'ah slot exists,
        // so a user who enabled Dhuhr but not Jumu'ah still gets a Friday
        // midday reminder.
        PrayerSlot(
          name: PrayerName.dhuhr,
          time: _timeFromNested(json['dhuhr']),
          iqamah: _timeFromNestedOrNull(json['dhuhr'], 'iqamah'),
        ),
        // Jumu'ah is additional, never a replacement for Dhuhr.
        if (hasJumuah)
          PrayerSlot(
            name: PrayerName.jumuah,
            time: _timeFromNested(jummah),
            iqamah: _timeFromNestedOrNull(jummah, 'iqamah'),
          ),
        PrayerSlot(
          name: PrayerName.asr,
          time: _timeFromNested(json['asr']),
          iqamah: _timeFromNestedOrNull(json['asr'], 'iqamah'),
        ),
        PrayerSlot(
          name: PrayerName.maghrib,
          time: _timeFromNested(json['maghrib']),
          iqamah: _timeFromNestedOrNull(json['maghrib'], 'iqamah'),
        ),
        PrayerSlot(
          name: PrayerName.isha,
          time: _timeFromNested(json['isha']),
          iqamah: _timeFromNestedOrNull(json['isha'], 'iqamah'),
        ),
      ],
    );
  }

  final DateTime date;
  final List<PrayerSlot> slots;

  List<PrayerSlot> get notifiable => slots
      .where((s) => s.isNotifiable && s.name != PrayerName.sunrise)
      .toList();

  static TimeOfDay _timeFromNested(Object? value, [String key = 'adhan']) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Missing prayer time entry');
    }
    return _timeFromValue(value[key]);
  }

  static TimeOfDay? _timeFromNestedOrNull(Object? value, String key) {
    if (value is! Map<String, dynamic>) return null;
    final raw = value[key];
    if (raw == null) return null;
    return _timeFromValue(raw);
  }

  static TimeOfDay _timeFromValue(Object? value) {
    if (value is! String) {
      throw const FormatException('Invalid prayer time');
    }
    final parts = value.split(':');
    if (parts.length < 2) throw const FormatException('Invalid prayer time');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw const FormatException('Invalid prayer time');
    }
    return TimeOfDay(hour: hour, minute: minute);
  }
}
