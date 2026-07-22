import 'package:flutter/material.dart';

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

  DateTime dateTimeOn(DateTime day) {
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }
}

class DailyPrayers {
  const DailyPrayers({required this.date, required this.slots});

  factory DailyPrayers.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    final jummah = json['jummah'];
    final isFriday = date.weekday == DateTime.friday;
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
        if (isFriday && jummah != null)
          PrayerSlot(
            name: PrayerName.jumuah,
            time: _timeFromNested(jummah),
            iqamah: _timeFromNestedOrNull(jummah, 'iqamah'),
          )
        else
          PrayerSlot(
            name: PrayerName.dhuhr,
            time: _timeFromNested(json['dhuhr']),
            iqamah: _timeFromNestedOrNull(json['dhuhr'], 'iqamah'),
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

  List<PrayerSlot> get notifiable =>
      slots.where((s) => s.name != PrayerName.sunrise).toList();

  static TimeOfDay _timeFromNested(Object? value, [String key = 'adhan']) {
    final map = value as Map<String, dynamic>;
    return _timeFromValue(map[key]);
  }

  static TimeOfDay? _timeFromNestedOrNull(Object? value, String key) {
    final map = value as Map<String, dynamic>;
    final raw = map[key];
    if (raw == null) return null;
    return _timeFromValue(raw);
  }

  static TimeOfDay _timeFromValue(Object? value) {
    final parts = (value as String).split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
