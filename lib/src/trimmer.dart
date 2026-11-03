import 'dart:async';
import 'package:image/image.dart' as img;
import 'package:path/path.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/platform/file_ops.dart';
import 'package:video_trimmer/src/utils/native_trimmer.dart';
import 'package:video_trimmer/src/utils/output_naming.dart';
import 'package:video_trimmer/src/utils/storage_dir.dart';
import 'package:video_trimmer/src/utils/thumbnail_generator.dart';

enum OutputType { video, gif }

enum TrimmerEvent { initialized }

/// Helps in loading video from file, saving trimmed video to a file
/// and gives video playback controls. Some of the helpful methods
/// are:
/// - [loadVideo()]
/// - [saveTrimmedVideo()]
/// - [videoPlaybackControl()]
class Trimmer {
  final StreamController<TrimmerEvent> _controller =
      StreamController<TrimmerEvent>.broadcast();

  VideoPlayerController? _videoPlayerController;

  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  /// The video path passed to the last [loadVideo].
  String? currentVideoPath;

  /// Listen to this stream to catch the events
  Stream<TrimmerEvent> get eventStream => _controller.stream;

  /// Whether a video has been loaded and its controller initialized.
  ///
  /// Widgets that mount after [loadVideo] completes can read this instead of
  /// waiting on [eventStream], which is a plain broadcast stream and so never
  /// replays the event they missed.
  bool get isVideoInitialized =>
      _videoPlayerController?.value.isInitialized ?? false;

  /// Bumped by every [loadVideo] and by [dispose], so a load that is still in
  /// flight can tell it has been superseded.
  int _loadGeneration = 0;
  bool _disposed = false;

  /// The current controller's pending initialize(), if any.
  Future<void>? _initializing;

  /// Disposes [controller] once its [initializing] future has settled.
  ///
  /// Disposing a VideoPlayerController while initialize() is still pending
  /// makes that initialize() never complete on Android, and can stall later
  /// controllers too. So a controller is never torn down mid-initialize.
  static Future<void> _release(
    VideoPlayerController? controller,
    Future<void>? initializing,
  ) async {
    if (controller == null) return;
    if (initializing != null) {
      try {
        await initializing;
      } catch (_) {
        // A failed initialize still leaves a controller to dispose.
      }
    }
    await controller.dispose();
  }

  /// Loads the video at [videoPath] into the player and the trim viewer.
  ///
  /// [videoPath] is a file path on Android, iOS, and macOS (`File(...).path`),
  /// and a blob: URL on the web. A picker's `XFile.path` is exactly that on
  /// every platform, so `loadVideo(videoPath: picked.xFile.path)` works
  /// everywhere.
  ///
  /// On native platforms, throws a `FileSystemException` if the file does not
  /// exist, rather than silently doing nothing.
  ///
  /// When called again before an earlier call finished, the newer call wins
  /// and only it emits [TrimmerEvent.initialized]. After [dispose], this does
  /// nothing.
  Future<void> loadVideo({required String videoPath}) async {
    if (_disposed) return;
    await ensureVideoExists(videoPath);
    final generation = ++_loadGeneration;
    bool superseded() => _disposed || generation != _loadGeneration;

    // Release the previous video before replacing it, otherwise every reload
    // leaks a controller and its platform-side player.
    final previous = _videoPlayerController;
    final previousInit = _initializing;
    _videoPlayerController = null;
    _initializing = null;
    await _release(previous, previousInit);
    // dispose() or a newer loadVideo() may have run during that await. Going
    // on would create a controller nobody releases.
    if (superseded()) return;

    currentVideoPath = videoPath;
    final controller = createVideoController(videoPath);
    _videoPlayerController = controller;
    final initializing = controller.initialize();
    _initializing = initializing;
    try {
      await initializing;
    } catch (_) {
      // A superseded load's failure is nobody's concern; whoever superseded it
      // releases the controller.
      if (superseded()) return;
      rethrow;
    } finally {
      if (identical(_initializing, initializing)) _initializing = null;
    }
    if (superseded()) return;
    if (!_controller.isClosed) {
      _controller.add(TrimmerEvent.initialized);
    }
  }

  /// Generates thumbnails from a video file based on a target FPS and width.
  ///
  /// - [videoPath] is the path to the video file.
  /// - [fpsGIF] is the target FPS for the thumbnails. Throws an error if
  /// exceeds 30.
  /// - [scaleGIF] is the maximum width for the thumbnails.
  /// - [qualityGIF] is the quality for the thumbnails.
  ///
  Future<List<Uint8List>> _generateGifImageBytes({
    required String videoPath,
    required int fpsGIF,
    required int scaleGIF,
    required int qualityGIF,
    required double startValue,
    required double endValue,
  }) async {
    if (fpsGIF > 30) {
      throw ArgumentError('GIF FPS cannot be greater than 30.');
    }

    final frameIntervalMs =
        (1000 / fpsGIF).round(); // Time between frames (in ms)

    List<Uint8List> thumbnails = [];

    // Only generate thumbnails between start and end positions
    for (int timeMs = startValue.toInt();
        timeMs <= endValue.toInt();
        timeMs += frameIntervalMs) {
      try {
        final thumbnail = await ThumbnailGenerator.thumbnailData(
          videoPath: videoPath,
          timeMs: timeMs,
          maxWidth: scaleGIF,
          quality: qualityGIF,
        );

        thumbnails.add(thumbnail);
      } catch (e) {
        debugPrint('Error generating thumbnail at ${timeMs}ms: $e');
      }
    }

    return thumbnails;
  }

  /// Generates a GIF from a video between [startValue] and [endValue].
  ///
  /// Returns the path to the saved GIF file.
  Future<String> _generateGifFromVideo({
    required String videoPath,
    required int fpsGIF,
    required int scaleGIF,
    required int qualityGIF,
    required double startValue,
    required double endValue,
    required String outputGifPath,
  }) async {
    // Step 1: Generate thumbnail frames
    final frames = await _generateGifImageBytes(
      videoPath: videoPath,
      fpsGIF: fpsGIF,
      scaleGIF: scaleGIF,
      qualityGIF: qualityGIF,
      startValue: startValue,
      endValue: endValue,
    );

    if (frames.isEmpty) {
      throw Exception('No frames were generated for the GIF.');
    }

    // Step 2: Create a list of img.Image frames
    final gifFrames = <img.Image>[];

    for (final frameBytes in frames) {
      final decodedImage = img.decodeImage(frameBytes);
      if (decodedImage != null) {
        gifFrames.add(decodedImage);
      }
    }

    // Step 3: Create GIF encoder
    final encoder = img.GifEncoder(
      repeat: 0, // 0 means loop forever
      samplingFactor: 1,
    );

    // Step 4: Add frames to encoder
    for (final frame in gifFrames) {
      encoder.addFrame(
        frame,
        duration: (100 / fpsGIF).round(), // duration per frame (ms)
      );
    }

    // Step 5: Encode and save GIF
    final gifBytes = encoder.finish();
    if (gifBytes == null) {
      throw Exception('Failed to encode GIF');
    }
    return writeOutputBytes(gifBytes, outputGifPath, 'image/gif');
  }

  /// Saves the trimmed video to file system.
  ///
  ///
  /// The required parameters are [startValue], [endValue] & [onSave].
  ///
  /// The optional parameters are [videoFolderName], [videoFileName],
  ///[fpsGIF], [scaleGIF].
  ///
  /// The `@required` parameter [startValue] is for providing a starting point
  /// to the trimmed video. To be specified in `milliseconds`.
  ///
  /// The `@required` parameter [endValue] is for providing an ending point
  /// to the trimmed video. To be specified in `milliseconds`.
  ///
  /// The `@required` parameter [onSave] receives the output path once the
  /// processing is complete, or `null` if the native trimmer could not
  /// produce a file.
  ///
  /// The parameter [videoFolderName] is used to
  /// pass a folder name which will be used for creating a new
  /// folder in the selected directory. The default value for
  /// it is `Trimmer`.
  ///
  /// The parameter [videoFileName] is used for giving
  /// a new name to the trimmed video file. By default the trimmed video is
  /// named as `<original_file_name>_trimmed:<date_time>.<video_extension>`.
  ///
  /// The parameter [storageDir] can be used for providing a storage
  /// location option. It accepts only [StorageDir] values. By default
  /// it is set to [applicationDocumentsDirectory]. Some of the
  /// storage types are:
  ///
  /// * [temporaryDirectory] (Only accessible from inside the app, can be
  /// cleared at anytime)
  ///
  /// * [applicationDocumentsDirectory] (Only accessible from inside the app)
  ///
  /// * [externalStorageDirectory] (Supports only `Android`, accessible externally)
  ///
  /// The parameters [fpsGIF] & [scaleGIF] are used only if the
  /// selected output format is `FileFormat.gif`.
  ///
  /// * [fpsGIF] for providing a FPS value (by default it is set
  /// to `10`)
  ///
  ///
  /// * [scaleGIF] for proving a width to output GIF, the height
  /// is selected by maintaining the aspect ratio automatically (by
  /// default it is set to `480`)
  ///
  /// * [qualityGIF] for providing a quality value for the GIF (by
  /// default it is set to `50`)
  ///
  ///
  ///
  /// * [outputType] can be `video` or `gif`.
  ///
  ///
  Future<void> saveTrimmedVideo({
    required double startValue,
    required double endValue,
    required Function(String? outputPath) onSave,
    int? fpsGIF,
    int? scaleGIF,
    int? qualityGIF,
    String? videoFolderName,
    String? videoFileName,
    StorageDir? storageDir,
    OutputType outputType = OutputType.video,
  }) async {
    final String? sourcePath = currentVideoPath;
    if (sourcePath == null) {
      throw StateError('No video loaded. Call loadVideo() before saving.');
    }

    final String videoPath = sourcePath;
    // On the web the path is a blob: URL with no file name in it; the output
    // is a blob: URL too, so the generated name is never seen there.
    final String fileExtension = outputType == OutputType.gif
        ? '.gif'
        : kIsWeb
            ? '.mp4'
            : trimmedVideoExtension(videoPath, defaultTargetPlatform);

    videoFolderName = sanitizeFileName(videoFolderName ?? 'Trimmer');
    final String outputFileName = buildOutputFileName(
      sourcePath: videoPath,
      timestamp: DateTime.now(),
      customName: videoFileName,
    );

    final String path = await prepareOutputFolder(
      videoFolderName,
      storageDir ?? StorageDir.applicationDocumentsDirectory,
    );

    final String outputPath = join(path, '$outputFileName$fileExtension');

    debugPrint('Trimming ${Duration(milliseconds: startValue.toInt())} to '
        '${Duration(milliseconds: endValue.toInt())} -> $outputPath');

    if (outputType == OutputType.gif) {
      final gifPath = await _generateGifFromVideo(
        videoPath: videoPath,
        fpsGIF: fpsGIF ?? 10,
        scaleGIF: scaleGIF ?? 480,
        qualityGIF: qualityGIF ?? 50,
        startValue: startValue,
        endValue: endValue,
        outputGifPath: outputPath,
      );

      onSave(gifPath);
    } else {
      final String saved;
      try {
        // Written straight to the destination; there is no temporary copy.
        // The web implementation returns a blob: URL instead.
        saved = await NativeTrimmer.trim(
          inputPath: videoPath,
          outputPath: outputPath,
          startMs: startValue.toInt(),
          endMs: endValue.toInt(),
        );
      } on PlatformException catch (e) {
        // A null path is the documented failure signal for onSave.
        debugPrint('video_trimmer: trimming failed: ${e.message}');
        onSave(null);
        return;
      }
      onSave(saved);
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
  Future<bool> videoPlaybackControl({
    required double startValue,
    required double endValue,
  }) async {
    final controller = videoPlayerController!;
    if (controller.value.isPlaying) {
      await controller.pause();
      return false;
    }
    // Start from the trim start whenever the playhead sits outside the range,
    // including before it, e.g. after the start handle was dragged past it.
    final position = controller.value.position.inMilliseconds;
    if (position < startValue.toInt() || position >= endValue.toInt()) {
      await controller.seekTo(Duration(milliseconds: startValue.toInt()));
    }
    await controller.play();
    return true;
  }

  /// Releases the video controller and the event stream.
  ///
  /// Call this from the [State.dispose] of whatever created the [Trimmer].
  /// The viewer widgets deliberately do not do it for you: they don't own the
  /// controller, and tearing it down from a child broke every subsequent
  /// `loadVideo` on the same instance.
  void dispose() {
    _disposed = true;
    _loadGeneration++;
    unawaited(_release(_videoPlayerController, _initializing));
    _videoPlayerController = null;
    _initializing = null;
    unawaited(ThumbnailGenerator.release());
    _controller.close();
  }
}
