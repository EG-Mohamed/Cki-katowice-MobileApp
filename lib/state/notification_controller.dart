import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/prayer.dart';

class NotificationController extends ChangeNotifier {
  static const String storageKey = 'enabled_prayers';
  static const List<PrayerName> notifiable = [
    PrayerName.fajr,
    PrayerName.dhuhr,
    PrayerName.asr,
    PrayerName.maghrib,
    PrayerName.isha,
    PrayerName.jumuah,
  ];

  Set<PrayerName> _enabled = {...notifiable};

  Set<PrayerName> get enabled => Set.unmodifiable(_enabled);
  bool get allEnabled => _enabled.length == notifiable.length;
  bool isEnabled(PrayerName name) => _enabled.contains(name);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final stored = prefs.getStringList(storageKey);
    if (stored == null) {
      _enabled = {...notifiable};
    } else {
      final storedNames = stored.toSet();
      _enabled = notifiable.where((p) => storedNames.contains(p.name)).toSet();
    }
    notifyListeners();
  }

  Future<void> toggle(PrayerName name) => setEnabled(name, !isEnabled(name));

  Future<void> setEnabled(PrayerName name, bool value) async {
    if (!notifiable.contains(name)) return;
    await load();
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
    await prefs.setStringList(storageKey, _enabled.map((p) => p.name).toList());
  }
}
