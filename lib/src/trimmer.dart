import 'dart:async';
import 'dart:io';
import 'package:video_player/video_player.dart';

enum TrimmerEvent { initialized }

/// Helps in loading video from file, saving trimmed video to a file
/// and gives video playback controls. Some of the helpful methods
/// are:
/// * [loadVideo()]
/// * [saveTrimmedVideo()]
/// * [videPlaybackControl()]
class Trimmer {
  final StreamController<TrimmerEvent> _controller =
      StreamController<TrimmerEvent>.broadcast();

  VideoPlayerController? _videoPlayerController;

  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  File? currentVideoFile;
  double videoStartPos = 0.0;
  double videoEndPos = 0.0;

  /// Listen to this stream to catch the events
  Stream<TrimmerEvent> get eventStream => _controller.stream;

  /// Loads a video using the path provided.
  ///
  /// Returns the loaded video file.
  Future<void> loadVideo({required File videoFile}) async {
    currentVideoFile = videoFile;
    if (videoFile.existsSync()) {
      _videoPlayerController = VideoPlayerController.file(currentVideoFile!);
      await _videoPlayerController!.initialize().then((_) {
        _videoPlayerController!.setLooping(true);
        _videoPlayerController!.play();
        _controller.add(TrimmerEvent.initialized);
      });
    }
  }

  /// For getting the video controller state, to know whether the
  /// video is playing or paused currently.
  ///
  /// The two required parameters are [startValue] & [endValue]
  ///
  /// * [startValue] is the current starting point of the video.
  /// * [endValue] is the current ending point of the video.
  ///
  /// Returns a `Future<bool>`, if `true` then video is playing
  /// otherwise paused.
  Future<bool> videPlaybackControl({
    required double startValue,
    required double endValue,
  }) async {
    if (videoPlayerController!.value.isPlaying) {
      await videoPlayerController!.pause();
      return false;
    } else {
      if (videoPlayerController!.value.position.inMilliseconds >=
          endValue.toInt()) {
        await videoPlayerController!
            .seekTo(Duration(milliseconds: startValue.toInt()));
        await videoPlayerController!.play();
        return true;
      } else {
        await videoPlayerController!.play();
        return true;
      }
    }
  }

  /// Clean up
  void dispose() {
    _controller.close();
  }
}
