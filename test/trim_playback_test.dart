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

  group('decideTrimPlaybackOnFrame', () {
    TrimPlaybackAction decide(int pos,
            {bool looping = false,
            bool playing = true,
            double end = 8000,
            double speed = 1.0}) =>
        decideTrimPlaybackOnFrame(
          estimatedPositionMs: pos,
          isPlaying: playing,
          isLooping: looping,
          durationMs: 30000,
          startMs: 2000,
          endMs: end,
          speed: speed,
        );

    test('acts exactly at a trim end inside the video', () {
      expect(decide(7990), TrimPlaybackAction.none);
      expect(decide(8000), TrimPlaybackAction.pause);
      expect(decide(8000, looping: true), TrimPlaybackAction.loop);
    });
    test('acts early at the end of the video, scaled by speed', () {
      expect(decide(29870, looping: true, end: 30000), TrimPlaybackAction.none);
      expect(decide(29880, looping: true, end: 30000), TrimPlaybackAction.loop);
      expect(decide(29770, looping: true, end: 30000, speed: 2.0),
          TrimPlaybackAction.loop);
    });
    test('ignores a paused player', () {
      expect(decide(9000, playing: false), TrimPlaybackAction.none);
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
    test('a looping player that wraps to 0 on its own goes back to the start',
        () {
      // Trim end at the very end of the video: the player loops before it
      // ever reports the trim end.
      expect(
        decideTrimPlayback(
          value: _value(positionMs: 40, looping: true),
          startMs: 24000,
          endMs: 30000,
          previousPositionMs: 29900,
        ),
        TrimPlaybackAction.loop,
      );
    });
    test('a jump back is only a wrap when the player loops', () {
      expect(
        decideTrimPlayback(
          value: _value(positionMs: 40),
          startMs: 24000,
          endMs: 30000,
          previousPositionMs: 29900,
        ),
        TrimPlaybackAction.none,
      );
    });
    test('a loop seek that lands just before the start is left alone', () {
      expect(
        decide(_value(positionMs: 1950, looping: true)),
        TrimPlaybackAction.none,
      );
      expect(
        decideTrimPlayback(
          value: _value(positionMs: 1950, looping: true),
          startMs: 2000,
          endMs: 8000,
          previousPositionMs: 8050,
        ),
        TrimPlaybackAction.none,
      );
    });
    test('moving forward from before the start is not a wrap', () {
      expect(
        decideTrimPlayback(
          value: _value(positionMs: 600, looping: true),
          startMs: 2000,
          endMs: 8000,
          previousPositionMs: 300,
        ),
        TrimPlaybackAction.none,
      );
    });
    test('ignores an empty range', () {
      expect(
        decideTrimPlaybackOnFrame(
          estimatedPositionMs: 9000,
          isPlaying: true,
          isLooping: true,
          durationMs: 30000,
          startMs: 5000,
          endMs: 5000,
        ),
        TrimPlaybackAction.none,
      );
      expect(
        decideTrimPlayback(
            value: _value(positionMs: 9000), startMs: 5000, endMs: 5000),
        TrimPlaybackAction.none,
      );
    });
  });
}
