import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models/prayer.dart';
import '../data/services/prayer_service.dart';

class PrayerController extends ChangeNotifier {
  PrayerController(this._service);

  final PrayerService _service;

  DailyPrayers? _day;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _hasError = false;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  DailyPrayers? get day => _day;
  Duration get remaining => _remaining;
  bool get isReady => _day != null;
  bool get hasError => _hasError;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  bool get isSelectedDateToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Future<void> load({DateTime? date}) async {
    final targetDate = date ?? _selectedDate;
    _selectedDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    _isLoading = true;
    _day = null;
    notifyListeners();
    try {
      _day = await _service.forDate(_selectedDate);
      _hasError = false;
      _startTicker();
      _recompute();
    } catch (_) {
      _hasError = true;
    } finally {
      _isLoading = false;
    }
    notifyListeners();
  }

  PrayerSlot? get nextPrayer {
    final day = _day;
    if (day == null) return null;
    final now = DateTime.now();
    for (final slot in day.notifiable) {
      if (slot.dateTimeOn(day.date).isAfter(now)) return slot;
    }
    return day.notifiable.first;
  }

  PrayerSlot? get currentPrayer {
    final day = _day;
    if (day == null) return null;
    final now = DateTime.now();
    PrayerSlot? current;
    for (final slot in day.notifiable) {
      if (!slot.dateTimeOn(day.date).isAfter(now)) {
        current = slot;
      }
    }
    return current;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _recompute();
      notifyListeners();
    });
  }

  void _recompute() {
    final day = _day;
    final next = nextPrayer;
    if (day == null || next == null) {
      _remaining = Duration.zero;
      return;
    }
    var target = next.dateTimeOn(day.date);
    final now = DateTime.now();
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    _remaining = target.difference(now);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
