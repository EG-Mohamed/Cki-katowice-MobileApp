import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

abstract class QuranPlaybackHandler extends BaseAudioHandler {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<bool> get playingStream;
  void setOnComplete(void Function() callback);
  void setOnError(void Function() callback);
  void setSkipHandlers({
    required void Function() onNext,
    required void Function() onPrevious,
  });
  Future<void> loadUrl(String url, MediaItem item);
  Future<void> disposePlayer();
}

class QuranAudioHandler extends QuranPlaybackHandler {
  QuranAudioHandler() {
    _sessionReady = _configureSession();
    _eventSub = _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[QuranAudioHandler] playbackEventStream error: $error');
        _onError?.call();
      },
    );
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onComplete?.call();
      }
    });
  }

  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  final AudioPlayer _player = AudioPlayer();
  late final Future<void> _sessionReady;
  late final StreamSubscription<PlaybackEvent> _eventSub;
  late final StreamSubscription<PlayerState> _stateSub;
  int _generation = 0;
  bool _disposed = false;

  void Function()? _onComplete;
  void Function()? _onError;

  AudioPlayer get player => _player;

  @override
  void setOnError(void Function() callback) {
    _onError = callback;
  }

  @override
  Stream<Duration> get positionStream => _player.positionStream;
  @override
  Stream<Duration?> get durationStream => _player.durationStream;
  @override
  Stream<bool> get playingStream => _player.playingStream;

  @override
  void setOnComplete(void Function() callback) {
    _onComplete = callback;
  }

  @override
  Future<void> loadUrl(String url, MediaItem item) async {
    final generation = ++_generation;
    await _sessionReady;
    if (_disposed || generation != _generation) return;
    await _player.pause();
    if (_disposed || generation != _generation) return;
    await _player.setUrl(url);
    if (_disposed || generation != _generation) return;
    mediaItem.add(item);
    // just_audio's play Future completes at pause/end, not when playback starts.
    unawaited(
      _player.play().catchError((Object error) {
        if (!_disposed && generation == _generation) _onError?.call();
      }),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    _generation++;
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
  }

  @override
  Future<void> skipToNext() async => _onNext?.call();

  @override
  Future<void> skipToPrevious() async => _onPrevious?.call();

  void Function()? _onNext;
  void Function()? _onPrevious;

  @override
  void setSkipHandlers({
    required void Function() onNext,
    required void Function() onPrevious,
  }) {
    _onNext = onNext;
    _onPrevious = onPrevious;
  }

  @override
  Future<void> disposePlayer() async {
    _disposed = true;
    _generation++;
    _onError = null;
    _onComplete = null;
    await _eventSub.cancel();
    await _stateSub.cancel();
    await _player.dispose();
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }
}
