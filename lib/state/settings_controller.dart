import 'package:flutter/material.dart';

import '../data/models/content.dart';
import '../data/services/settings_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._service);

  final SettingsService _service;

  SiteSettings? _settings;
  bool _isLoading = false;
  int _generation = 0;
  bool _disposed = false;

  SiteSettings? get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    final generation = ++_generation;
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _service.fetch();
      if (_disposed || generation != _generation) return;
      _settings = result;
    } catch (_) {
      if (_disposed || generation != _generation) return;
    } finally {
      if (!_disposed && generation == _generation) _isLoading = false;
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
