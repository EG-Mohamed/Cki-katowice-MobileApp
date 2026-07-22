import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/prayer.dart';

class NotificationController extends ChangeNotifier {
  static const String _key = 'enabled_prayers';
  static const List<PrayerName> notifiable = [
    PrayerName.fajr,
    PrayerName.dhuhr,
    PrayerName.asr,
    PrayerName.maghrib,
    PrayerName.isha,
    PrayerName.jumuah,
  ];

  Set<PrayerName> _enabled = {...notifiable};

  Set<PrayerName> get enabled => _enabled;
  bool get allEnabled => _enabled.length == notifiable.length;
  bool isEnabled(PrayerName name) => _enabled.contains(name);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key);
    if (stored == null) {
      _enabled = {...notifiable};
    } else {
      final storedNames = stored.toSet();
      _enabled = notifiable.where((p) => storedNames.contains(p.name)).toSet();
    }
    notifyListeners();
  }

  Future<void> toggle(PrayerName name) async {
    if (_enabled.contains(name)) {
      _enabled.remove(name);
    } else {
      _enabled.add(name);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setEnabled(PrayerName name, bool value) async {
    if (value) {
      _enabled.add(name);
    } else {
      _enabled.remove(name);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setAll(bool value) async {
    _enabled = value ? {...notifiable} : <PrayerName>{};
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _enabled.map((p) => p.name).toList());
  }
}
