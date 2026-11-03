import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/trim_viewer/trim_playback.dart';

VideoPlayerValue _value({
  int positionMs = 0,
  bool playing = true,
  bool looping = false,
  bool buffering = false,
  double speed = 1.0,
}) =>
    VideoPlayerValue(
      duration: const Duration(seconds: 30),
      position: Duration(milliseconds: positionMs),
      isInitialized: true,
      isPlaying: playing,
      isLooping: looping,
      isBuffering: buffering,
      playbackSpeed: speed,
    );

void main() {
  group('Playhead', () {
    late int now;
    late Playhead playhead;
    setUp(() {
      now = 0;
      playhead = Playhead(clockMs: () => now);
    });

    test('extrapolates from the last report while playing', () {
      playhead.sync(_value(positionMs: 5000));
      now = 250;
      expect(playhead.positionMs, 5250);
    });

    test('re-anchors on every report, so it cannot drift', () {
      playhead.sync(_value(positionMs: 5000));
      now = 400;
      // The player was actually slower than wall time; the next report wins.
      playhead.sync(_value(positionMs: 5300));
      expect(playhead.positionMs, 5300);
      now = 500;
      expect(playhead.positionMs, 5400);
    });

    test('scales by playback speed', () {
      playhead.sync(_value(positionMs: 1000, speed: 2.0));
      now = 500;
      expect(playhead.positionMs, 2000);
    });

    test('holds still while paused or buffering', () {
      playhead.sync(_value(positionMs: 1000, playing: false));
      now = 800;
      expect(playhead.positionMs, 1000);
      playhead.sync(_value(positionMs: 1000, buffering: true));
      now = 1600;
      expect(playhead.positionMs, 1000);
    });

    test('never extrapolates past the cap if the player stalls', () {
      playhead.sync(_value(positionMs: 0));
      now = 60000;
      expect(playhead.positionMs, Playhead.maxExtrapolationMs);
    });

    test('jumpTo moves the anchor immediately', () {
      playhead.sync(_value(positionMs: 9000));
      playhead.jumpTo(2000);
      now = 100;
      expect(playhead.positionMs, 2100);
    });
  });

  group('decideTrimPlayback', () {
    TrimPlaybackAction decide(VideoPlayerValue v) =>
        decideTrimPlayback(value: v, startMs: 2000, endMs: 8000);

    test('does nothing inside the range', () {
      expect(decide(_value(positionMs: 5000)), TrimPlaybackAction.none);
    });
    test('pauses at the end of the range', () {
      expect(decide(_value(positionMs: 8000)), TrimPlaybackAction.pause);
    });
    test('loops at the end of the range when the controller loops', () {
      expect(decide(_value(positionMs: 8100, looping: true)),
          TrimPlaybackAction.loop);
    });
    test('ignores a paused player', () {
      expect(decide(_value(positionMs: 9000, playing: false)),
          TrimPlaybackAction.none);
    });
    test('ignores an empty range', () {
      expect(
        decideTrimPlayback(
            value: _value(positionMs: 9000), startMs: 5000, endMs: 5000),
        TrimPlaybackAction.none,
      );
    });
  });
}
