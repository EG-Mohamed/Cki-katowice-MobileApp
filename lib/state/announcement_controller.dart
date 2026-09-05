import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/content.dart';
import '../data/services/announcement_service.dart';

class AnnouncementController extends ChangeNotifier {
  AnnouncementController(this._service);

  static const String _dismissKey = 'dismissed_announcements';

  final AnnouncementService _service;

  List<Announcement> _all = const [];
  Set<String> _dismissed = {};
  bool _isLoading = false;
  int _generation = 0;
  bool _disposed = false;

  bool get isLoading => _isLoading;

  List<Announcement> get visible {
    return _all.where((item) => !_dismissed.contains(item.id)).toList();
  }

  Announcement? get top {
    final items = visible;
    if (items.isEmpty) return null;
    items.sort((a, b) => _rank(a.type).compareTo(_rank(b.type)));
    return items.first;
  }

  Future<void> load() async {
    final generation = ++_generation;
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _service.active();
      if (_disposed || generation != _generation) return;
      _all = result;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      _all = const [];
    } finally {
      if (!_disposed && generation == _generation) _isLoading = false;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_dismissKey);
    if (stored != null) {
      _dismissed = stored.toSet();
      notifyListeners();
    }
  }

  Future<void> dismiss(String id) async {
    _dismissed.add(id);
    await _persist();
    if (!_disposed) notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_dismissKey, _dismissed.toList());
  }

  int _rank(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.urgent:
        return 0;
      case AnnouncementType.maintenance:
        return 1;
      case AnnouncementType.general:
        return 2;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
