import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/prayer_time.dart';
import '../data/models/prayer.dart';
import '../data/services/prayer_service.dart';

class PrayerController extends ChangeNotifier with WidgetsBindingObserver {
  PrayerController(this._service) {
    WidgetsBinding.instance.addObserver(this);
  }

  final PrayerService _service;

  DailyPrayers? _day;
  Timer? _ticker;
  PrayerName? _lastNextPrayer;
  final Set<String> _firedKeys = <String>{};
  void Function(DailyPrayers day, PrayerSlot slot)? onPrayerDue;
  final ValueNotifier<Duration> remainingListenable = ValueNotifier<Duration>(
    Duration.zero,
  );
  bool _hasError = false;
  bool _isLoading = false;
  DateTime _selectedDate = prayerToday();

  DailyPrayers? get day => _day;
  Duration get remaining => remainingListenable.value;
  bool get isReady => _day != null;
  bool get hasError => _hasError;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  bool get isSelectedDateToday {
    final now = prayerToday();
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
      _lastNextPrayer = nextPrayer?.name;
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
    final now = prayerNow();
    for (final slot in day.notifiable) {
      if (prayerInstant(day.date, slot.time).isAfter(now)) return slot;
    }
    return day.notifiable.first;
  }

  PrayerSlot? get currentPrayer {
    final day = _day;
    if (day == null) return null;
    final now = prayerNow();
    PrayerSlot? current;
    for (final slot in day.notifiable) {
      if (!prayerInstant(day.date, slot.time).isAfter(now)) {
        current = slot;
      }
    }
    return current;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = nextPrayer?.name;
      _recompute();
      if (next != _lastNextPrayer) {
        _lastNextPrayer = next;
        notifyListeners();
      }
    });
  }

  void _recompute() {
    final day = _day;
    final next = nextPrayer;
    if (day == null || next == null) {
      remainingListenable.value = Duration.zero;
      return;
    }
    var target = prayerInstant(day.date, next.time);
    final now = prayerNow();
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    remainingListenable.value = target.difference(now);
    _fireDuePrayers(day, now);
  }

  void _fireDuePrayers(DailyPrayers day, DateTime now) {
    final callback = onPrayerDue;
    if (callback == null || !isSelectedDateToday) return;
    for (final slot in day.notifiable) {
      final at = prayerInstant(day.date, slot.time);
      if (at.isAfter(now)) continue;
      if (now.difference(at) > const Duration(minutes: 1)) continue;
      final key = _firedKey(day.date, slot.name);
      if (!_firedKeys.add(key)) continue;
      callback(day, slot);
    }
  }

  String _firedKey(DateTime date, PrayerName name) =>
      '${date.year}-${date.month}-${date.day}-${name.name}';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = prayerToday();
      final selected = _selectedDate;
      final dateChanged =
          selected.year != now.year ||
          selected.month != now.month ||
          selected.day != now.day;
      if (dateChanged) {
        _firedKeys.clear();
        unawaited(load(date: now));
      } else if (_day != null) {
        _recompute();
        _startTicker();
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    remainingListenable.dispose();
    super.dispose();
  }
}
