import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/audio/audio_handler.dart';
import '../data/models/mp3quran.dart';

class PlaybackProgress {
  const PlaybackProgress({
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final Duration position;
  final Duration duration;

  double get value {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }
}

class QuranPlayerController extends ChangeNotifier {
  QuranPlayerController(this._handlerFactory);

  static const String _reciterKey = 'quran_reciter_id';
  static const String _moshafKey = 'quran_moshaf_id';

  final Future<QuranAudioHandler> Function() _handlerFactory;
  QuranAudioHandler? _handler;
  Future<QuranAudioHandler>? _initializingHandler;
  final ValueNotifier<PlaybackProgress> progress =
      ValueNotifier<PlaybackProgress>(const PlaybackProgress());

  Reciter? _reciter;
  Moshaf? _moshaf;
  List<MoshafSurah> _playlist = const [];
  int _index = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _autoplayNext = true;
  String? _radioName;

  int? _restoredReciterId;
  int? _restoredMoshafId;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<bool>? _playingSub;

  Reciter? get reciter => _reciter;
  Moshaf? get moshaf => _moshaf;
  List<MoshafSurah> get playlist => _playlist;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get autoplayNext => _autoplayNext;
  String? get radioName => _radioName;
  bool get isRadio => _radioName != null;

  bool get hasSurahTrack =>
      _moshaf != null && _index >= 0 && _index < _playlist.length;
  bool get hasTrack => hasSurahTrack || isRadio;

  MoshafSurah? get currentSurah => hasSurahTrack ? _playlist[_index] : null;

  bool get hasNext => hasSurahTrack && _index + 1 < _playlist.length;
  bool get hasPrevious => hasSurahTrack && _index > 0;

  int? get restoredReciterId => _restoredReciterId;
  int? get restoredMoshafId => _restoredMoshafId;

  Future<QuranAudioHandler> _ensureHandler() async {
    final existing = _handler;
    if (existing != null) return existing;
    final pending = _initializingHandler ??= _handlerFactory();
    late final QuranAudioHandler handler;
    try {
      handler = await pending;
    } catch (_) {
      _initializingHandler = null;
      rethrow;
    }
    _handler = handler;
    handler.setOnComplete(_onComplete);
    handler.setOnError(_onError);
    handler.setSkipHandlers(onNext: next, onPrevious: previous);
    _posSub = handler.positionStream.listen((value) {
      progress.value = PlaybackProgress(
        position: value,
        duration: progress.value.duration,
      );
    });
    _durSub = handler.durationStream.listen((value) {
      progress.value = PlaybackProgress(
        position: progress.value.position,
        duration: value ?? Duration.zero,
      );
    });
    _playingSub = handler.playingStream.listen((playing) {
      if (playing != _isPlaying) {
        _isPlaying = playing;
        notifyListeners();
      }
    });
    return handler;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _restoredReciterId = prefs.getInt(_reciterKey);
    _restoredMoshafId = prefs.getInt(_moshafKey);
  }

  void setReciter(Reciter reciter, Moshaf moshaf, List<MoshafSurah> suwar) {
    _reciter = reciter;
    _moshaf = moshaf;
    _playlist = suwar.where((surah) => moshaf.hasSurah(surah.id)).toList();
    unawaited(_persistSelection());
    notifyListeners();
  }

  Future<void> playSurah(int surahId) async {
    if (_moshaf == null) return;
    final index = _playlist.indexWhere((surah) => surah.id == surahId);
    if (index < 0) return;
    await _loadAndPlay(index);
  }

  Future<void> playRadio(String name, String url) async {
    debugPrint('[QuranPlayer] playRadio start: name=$name url=$url');
    _isLoading = true;
    _radioName = name;
    _index = -1;
    progress.value = const PlaybackProgress();
    notifyListeners();
    try {
      final handler = await _ensureHandler();
      await handler.loadUrl(
        url,
        MediaItem(id: url, title: name, album: 'Quran Radio'),
      );
      debugPrint('[QuranPlayer] playRadio loadUrl succeeded: name=$name');
    } catch (e, st) {
      debugPrint('[QuranPlayer] playRadio FAILED: name=$name url=$url error=$e');
      debugPrint('[QuranPlayer] stack: $st');
      _radioName = null;
      _isPlaying = false;
    } finally {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (!hasTrack) return;
    final handler = await _ensureHandler();
    if (_isPlaying) {
      await handler.pause();
    } else {
      await handler.play();
    }
  }

  Future<void> next() async {
    if (!hasNext) return;
    await _loadAndPlay(_index + 1);
  }

  Future<void> previous() async {
    if (!hasPrevious) return;
    await _loadAndPlay(_index - 1);
  }

  Future<void> seek(Duration to) async {
    if (!hasTrack) return;
    await (await _ensureHandler()).seek(to);
  }

  Future<void> stop() async {
    await _handler?.stop();
    _index = -1;
    _radioName = null;
    _isPlaying = false;
    progress.value = const PlaybackProgress();
    notifyListeners();
  }

  void setAutoplayNext(bool value) {
    _autoplayNext = value;
    notifyListeners();
  }

  Future<void> _loadAndPlay(int index) async {
    final moshaf = _moshaf;
    final reciter = _reciter;
    if (moshaf == null || index < 0 || index >= _playlist.length) return;
    _isLoading = true;
    _index = index;
    _radioName = null;
    progress.value = const PlaybackProgress();
    notifyListeners();
    try {
      final handler = await _ensureHandler();
      final surah = _playlist[index];
      await handler.loadUrl(
        moshaf.audioUrlFor(surah.id),
        MediaItem(
          id: '${moshaf.id}-${surah.id}',
          title: surah.name,
          artist: reciter?.name,
          album: reciter?.name,
        ),
      );
    } catch (_) {
      _index = -1;
      _isPlaying = false;
    } finally {
      _isLoading = false;
    }
    notifyListeners();
  }

  void _onComplete() {
    if (_autoplayNext && hasNext) {
      unawaited(_loadAndPlay(_index + 1));
    } else {
      unawaited(stop());
    }
  }

  void _onError() {
    unawaited(stop());
  }

  Future<void> _persistSelection() async {
    final reciter = _reciter;
    final moshaf = _moshaf;
    if (reciter == null || moshaf == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reciterKey, reciter.id);
    await prefs.setInt(_moshafKey, moshaf.id);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _playingSub?.cancel();
    progress.dispose();
    final handler = _handler;
    if (handler != null) unawaited(handler.disposePlayer());
    super.dispose();
  }
}
