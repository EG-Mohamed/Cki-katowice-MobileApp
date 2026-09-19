import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/api_client.dart';

class LocaleController extends ChangeNotifier {
  LocaleController(this._apiClient) {
    _apiClient.locale = _locale.languageCode;
  }

  static const String _key = 'app_locale';
  static const List<Locale> supported = [
    Locale('en'),
    Locale('pl'),
    Locale('ar'),
  ];

  /// The app is used mainly by the Polish Muslim community in Katowice, so
  /// an unrecognised device language falls back to Polish rather than
  /// English.
  static const Locale _fallback = Locale('pl');

  final ApiClient _apiClient;

  Locale _locale = _fallback;

  Locale get locale => _locale;
  bool get isRtl => _locale.languageCode == 'ar';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && supported.any((l) => l.languageCode == code)) {
      _locale = Locale(code);
    } else {
      // First run: follow the device's preferred language, falling back to
      // Polish for anything the app doesn't ship. Persist the decision so
      // background prayer-time refreshes (which cannot read device locale)
      // see the same language.
      _locale = _resolveDeviceLocale();
      await prefs.setString(_key, _locale.languageCode);
    }
    _apiClient.locale = _locale.languageCode;
    notifyListeners();
  }

  Locale _resolveDeviceLocale() {
    for (final deviceLocale in PlatformDispatcher.instance.locales) {
      for (final candidate in supported) {
        if (candidate.languageCode == deviceLocale.languageCode) {
          return candidate;
        }
      }
    }
    return _fallback;
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    _apiClient.locale = locale.languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    notifyListeners();
  }
}
