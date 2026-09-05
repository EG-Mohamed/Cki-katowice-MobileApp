import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:ckikatowice/data/audio/audio_handler.dart';
import 'package:ckikatowice/state/quran_player_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _Handler extends QuranPlaybackHandler {
  int completeBindings = 0;
  bool disposed = false;
  final urls = <String>[];
  final positions = StreamController<Duration>.broadcast();
  final durations = StreamController<Duration?>.broadcast();
  final playing = StreamController<bool>.broadcast();
  @override
  Stream<Duration> get positionStream => positions.stream;
  @override
  Stream<Duration?> get durationStream => durations.stream;
  @override
  Stream<bool> get playingStream => playing.stream;
  @override
  void setOnComplete(void Function() callback) {
    completeBindings++;
  }

  @override
  void setOnError(void Function() callback) {}
  @override
  void setSkipHandlers({
    required void Function() onNext,
    required void Function() onPrevious,
  }) {}
  @override
  Future<void> loadUrl(String url, MediaItem item) async {
    urls.add(url);
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> disposePlayer() async {
    disposed = true;
    await positions.close();
    await durations.close();
    await playing.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'concurrent playback initializes once and latest request wins',
    () async {
      final initialized = Completer<QuranPlaybackHandler>();
      var calls = 0;
      final controller = QuranPlayerController(() {
        calls++;
        return initialized.future;
      });
      final first = controller.playRadio('first', 'https://first');
      final second = controller.playRadio('second', 'https://second');
      final handler = _Handler();
      initialized.complete(handler);
      await Future.wait([first, second]);
      expect(calls, 1);
      expect(handler.completeBindings, 1);
      expect(handler.urls, ['https://second']);
      expect(controller.isLoading, false);
      controller.dispose();
    },
  );
  test('stop while initializing never starts stale playback', () async {
    final initialized = Completer<QuranPlaybackHandler>();
    final controller = QuranPlayerController(() => initialized.future);
    final play = controller.playRadio('radio', 'https://radio');
    await controller.stop();
    final handler = _Handler();
    initialized.complete(handler);
    await play;
    expect(handler.urls, isEmpty);
    expect(controller.hasTrack, false);
    expect(controller.isLoading, false);
    controller.dispose();
  });
  test('late handler initialization is disposed with its controller', () async {
    final initialized = Completer<QuranPlaybackHandler>();
    final controller = QuranPlayerController(() => initialized.future);
    final play = controller.playRadio('radio', 'https://radio');
    controller.dispose();
    final handler = _Handler();
    initialized.complete(handler);
    await play;
    expect(handler.disposed, true);
  });
}
