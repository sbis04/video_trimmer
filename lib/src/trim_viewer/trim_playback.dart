import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

/// Where the playhead is between the player's position updates.
///
/// video_player only reports its position every few hundred milliseconds, so
/// the viewers used to run their own AnimationController beside it. That
/// clock never looked at the player again, so it drifted after pause and
/// resume (#137, #212) and ignored playback speed (#218). This re-anchors on
/// every player update and only extrapolates in between.
class Playhead {
  Playhead({@visibleForTesting int Function()? clockMs})
      : _clockMs = clockMs ?? _defaultClockMs;

  static final Stopwatch _stopwatch = Stopwatch()..start();
  static int _defaultClockMs() => _stopwatch.elapsedMilliseconds;

  /// Never extrapolate further than this past the last report, so a stalled
  /// player cannot run the scrubber off on its own.
  static const int maxExtrapolationMs = 1000;

  final int Function() _clockMs;
  int _anchorPositionMs = 0;
  int _anchorClockMs = 0;
  double _speed = 1.0;
  bool _advancing = false;

  void sync(VideoPlayerValue value) {
    _anchorPositionMs = value.position.inMilliseconds;
    _anchorClockMs = _clockMs();
    _speed = value.playbackSpeed;
    _advancing = value.isPlaying && !value.isBuffering;
  }

  /// Moves the anchor without waiting for the player, e.g. right after a seek.
  void jumpTo(int positionMs) {
    _anchorPositionMs = positionMs;
    _anchorClockMs = _clockMs();
  }

  int get positionMs {
    if (!_advancing) return _anchorPositionMs;
    final elapsed = (_clockMs() - _anchorClockMs).clamp(0, maxExtrapolationMs);
    return _anchorPositionMs + (elapsed * _speed).round();
  }
}

/// What the viewer should do with the player after a position update.
enum TrimPlaybackAction { none, pause, loop }

/// How far before the trim start a looping player has to land before a
/// backwards jump counts as the player's own wrap, so a seek that lands a
/// little early never triggers another one.
const int loopWrapToleranceMs = 100;

/// Playback has reached the end of the trim range: pause it, or wrap back to
/// the start when the controller is set to loop (#237).
///
/// [previousPositionMs] is the position from the update before this one. When
/// the trim end is the end of the video, a looping player wraps to `0` on its
/// own, often before it ever reports a position at the trim end. A backwards
/// jump to before the trim start is that wrap, and is also sent back to the
/// trim start.
TrimPlaybackAction decideTrimPlayback({
  required VideoPlayerValue value,
  required double startMs,
  required double endMs,
  int? previousPositionMs,
}) {
  if (!value.isPlaying || endMs <= startMs) return TrimPlaybackAction.none;
  final position = value.position.inMilliseconds;
  if (position >= endMs.toInt()) {
    return value.isLooping ? TrimPlaybackAction.loop : TrimPlaybackAction.pause;
  }
  final wrapped = value.isLooping &&
      previousPositionMs != null &&
      position < previousPositionMs &&
      position < startMs - loopWrapToleranceMs;
  return wrapped ? TrimPlaybackAction.loop : TrimPlaybackAction.none;
}

/// Keeps a trim viewer's scrubber and playback state in step with the shared
/// [VideoPlayerController], and confines playback to the trim range.
class TrimPlayback {
  TrimPlayback({
    required this.player,
    required TickerProvider vsync,
    required this.range,
    required this.onPlayingChanged,
    required this.onFrame,
  }) {
    _ticker = vsync.createTicker((_) => onFrame());
  }

  final VideoPlayerController player;

  /// The current trim range in milliseconds.
  final ({double start, double end}) Function() range;

  /// Called only when playback starts or stops, never per frame. Calling the
  /// consumer's onChangePlaybackState on every position update made any
  /// consumer that seeks or plays from it re-enter forever (#236).
  final void Function(bool playing) onPlayingChanged;

  /// Called every frame while playing, to repaint the scrubber.
  final VoidCallback onFrame;

  final Playhead _playhead = Playhead();
  late final Ticker _ticker;
  bool? _reportedPlaying;
  bool _loopSeekInFlight = false;
  int? _lastPositionMs;

  void attach() {
    player.addListener(_onPlayerValue);
    _onPlayerValue();
  }

  /// Stops listening without notifying anyone, so it is safe from dispose().
  void detach() {
    player.removeListener(_onPlayerValue);
    if (_ticker.isTicking) _ticker.stop();
  }

  void dispose() {
    detach();
    _ticker.dispose();
  }

  /// The estimated playhead, kept inside the trim range.
  int get positionMs {
    final r = range();
    final p = _playhead.positionMs;
    if (p < r.start) return r.start.toInt();
    if (p > r.end) return r.end.toInt();
    return p;
  }

  /// The scrubber's x, mapped linearly from the trim range onto
  /// `[startX, endX]`.
  double scrubberX({required double startX, required double endX}) {
    final r = range();
    final span = r.end - r.start;
    if (span <= 0) return startX;
    return startX + (positionMs - r.start) / span * (endX - startX);
  }

  void _onPlayerValue() {
    final value = player.value;
    if (!value.isInitialized) return;
    _playhead.sync(value);

    final r = range();
    final action = decideTrimPlayback(
      value: value,
      startMs: r.start,
      endMs: r.end,
      previousPositionMs: _lastPositionMs,
    );
    _lastPositionMs = value.position.inMilliseconds;
    switch (action) {
      case TrimPlaybackAction.loop:
        if (!_loopSeekInFlight) {
          _loopSeekInFlight = true;
          _playhead.jumpTo(r.start.toInt());
          player
              .seekTo(Duration(milliseconds: r.start.toInt()))
              .whenComplete(() => _loopSeekInFlight = false);
        }
      case TrimPlaybackAction.pause:
        player.pause();
      case TrimPlaybackAction.none:
        break;
    }

    final playing = value.isPlaying && action != TrimPlaybackAction.pause;
    if (playing && !_ticker.isTicking) _ticker.start();
    if (!playing && _ticker.isTicking) _ticker.stop();
    if (_reportedPlaying != playing) {
      _reportedPlaying = playing;
      onPlayingChanged(playing);
    }
    onFrame();
  }
}
