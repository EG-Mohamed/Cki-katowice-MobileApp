import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/utils/prayer_time.dart';
import '../data/models/prayer.dart';
import '../data/services/prayer_service.dart';

class PrayerController extends ChangeNotifier with WidgetsBindingObserver {
  PrayerController(this._service, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _selectedDate = _today;
    WidgetsBinding.instance.addObserver(this);
  }
  final PrayerService _service;
  final DateTime Function() _now;
  DailyPrayers? _day;
  DailyPrayers? _tomorrow;
  Timer? _ticker;
  int _generation = 0;
  bool _disposed = false;
  bool _followToday = true;
  bool _hasError = false;
  bool _isLoading = false;
  late DateTime _selectedDate;
  final remainingListenable = ValueNotifier<Duration>(Duration.zero);

  tz.TZDateTime get _instant => tz.TZDateTime.from(_now(), prayerLocation);
  DateTime get _today {
    final now = _instant;
    return DateTime(now.year, now.month, now.day);
  }

  DailyPrayers? get day => _day;
  Duration get remaining => remainingListenable.value;
  bool get isReady => _day != null;
  bool get hasError => _hasError;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  bool get isSelectedDateToday => _selectedDate == _today;

  Future<void> load({DateTime? date}) async {
    if (_disposed) return;
    final generation = ++_generation;
    final target = date ?? (_followToday ? _today : _selectedDate);
    _selectedDate = DateTime(target.year, target.month, target.day);
    _followToday = _selectedDate == _today;
    _ticker?.cancel();
    _day = null;
    _tomorrow = null;
    _isLoading = true;
    _hasError = false;
    remainingListenable.value = Duration.zero;
    notifyListeners();
    try {
      final loaded = await _service.forDate(_selectedDate);
      if (_disposed || generation != _generation) return;
      _day = loaded;
      _isLoading = false;
      _recompute();
      _startTicker();
      notifyListeners();
      if (_followToday) unawaited(_loadTomorrow(loaded.date, generation));
    } catch (_) {
      if (_disposed || generation != _generation) return;
      _hasError = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTomorrow(DateTime date, int generation) async {
    try {
      final tomorrow = await _service.forDate(
        DateTime(date.year, date.month, date.day + 1),
      );
      if (_disposed || generation != _generation) return;
      _tomorrow = tomorrow;
      _recompute();
      notifyListeners();
    } catch (_) {
      /* Today's timetable remains usable offline. */
    }
  }

  ({PrayerSlot slot, DateTime at})? get _next {
    final now = _instant;
    final candidates = <({PrayerSlot slot, DateTime at})>[];
    for (final day in [_day, if (isSelectedDateToday) _tomorrow]) {
      if (day == null) continue;
      for (final slot in day.notifiable) {
        final at = prayerInstant(day.date, slot.time);
        if (at.isAfter(now)) candidates.add((slot: slot, at: at));
      }
    }
    candidates.sort((a, b) => a.at.compareTo(b.at));
    return candidates.isEmpty ? null : candidates.first;
  }

  PrayerSlot? get nextPrayer => _next?.slot;
  DateTime? get nextPrayerAt => _next?.at;
  PrayerSlot? get currentPrayer {
    final day = _day;
    if (day == null || !isSelectedDateToday) return null;
    PrayerSlot? current;
    DateTime? latest;
    for (final slot in day.notifiable) {
      final at = prayerInstant(day.date, slot.time);
      if (!at.isAfter(_instant) && (latest == null || at.isAfter(latest))) {
        latest = at;
        current = slot;
      }
    }
    return current;
  }

  void _startTicker() {
    _ticker?.cancel();
    final state = WidgetsBinding.instance.lifecycleState;
    if (!_followToday ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      return;
    }
    var lastNext = nextPrayerAt;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_followToday && _selectedDate != _today) {
        unawaited(load(date: _today));
        return;
      }
      _recompute();
      final next = nextPrayerAt;
      if (next != lastNext) {
        lastNext = next;
        notifyListeners();
      }
    });
  }

  void _recompute() {
    final at = nextPrayerAt;
    final difference = at?.difference(_instant) ?? Duration.zero;
    remainingListenable.value = difference.isNegative
        ? Duration.zero
        : difference;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_followToday && _selectedDate != _today) {
        unawaited(load(date: _today));
      } else {
        _recompute();
        _startTicker();
      }
    } else {
      _ticker?.cancel();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    remainingListenable.dispose();
    super.dispose();
  }
}
