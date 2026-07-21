import 'package:flutter/material.dart';

enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

class PrayerSlot {
  const PrayerSlot({
    required this.name,
    required this.time,
    this.isNotifiable = true,
  });

  final PrayerName name;
  final TimeOfDay time;
  final bool isNotifiable;

  DateTime dateTimeOn(DateTime day) {
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }
}

class DailyPrayers {
  const DailyPrayers({required this.date, required this.slots});

  factory DailyPrayers.fromJson(Map<String, dynamic> json) {
    return DailyPrayers(
      date: DateTime.parse(json['date'] as String),
      slots: [
        PrayerSlot(name: PrayerName.fajr, time: _timeFromNested(json['fajr'])),
        PrayerSlot(
          name: PrayerName.sunrise,
          time: _timeFromValue(json['sunrise']),
          isNotifiable: false,
        ),
        PrayerSlot(
          name: PrayerName.dhuhr,
          time: _timeFromNested(json['dhuhr']),
        ),
        PrayerSlot(name: PrayerName.asr, time: _timeFromNested(json['asr'])),
        PrayerSlot(
          name: PrayerName.maghrib,
          time: _timeFromNested(json['maghrib']),
        ),
        PrayerSlot(name: PrayerName.isha, time: _timeFromNested(json['isha'])),
      ],
    );
  }

  final DateTime date;
  final List<PrayerSlot> slots;

  List<PrayerSlot> get notifiable =>
      slots.where((s) => s.name != PrayerName.sunrise).toList();

  static TimeOfDay _timeFromNested(Object? value) {
    final map = value as Map<String, dynamic>;
    return _timeFromValue(map['adhan']);
  }

  static TimeOfDay _timeFromValue(Object? value) {
    final parts = (value as String).split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
