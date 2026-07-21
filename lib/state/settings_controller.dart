import 'package:flutter/material.dart';

import '../data/models/content.dart';
import '../data/services/settings_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._service);

  final SettingsService _service;

  SiteSettings? _settings;
  bool _isLoading = false;

  SiteSettings? get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _service.fetch();
    } catch (_) {
    } finally {
      _isLoading = false;
    }
    notifyListeners();
  }
}
