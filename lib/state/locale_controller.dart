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

  final ApiClient _apiClient;

  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isRtl => _locale.languageCode == 'ar';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && supported.any((l) => l.languageCode == code)) {
      _locale = Locale(code);
      _apiClient.locale = code;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    _apiClient.locale = locale.languageCode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}
