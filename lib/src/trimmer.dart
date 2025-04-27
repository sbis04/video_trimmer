import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter_native_video_trimmer/flutter_native_video_trimmer.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path/path.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/utils/storage_dir.dart';

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

  File? currentVideoFile;

  final _videoTrimmer = VideoTrimmer();

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
        _controller.add(TrimmerEvent.initialized);
      });
    }
  }

  Future<String> _createFolderInAppDocDir(
    String folderName,
    StorageDir? storageDir,
  ) async {
    Directory? directory;

    if (storageDir == null) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      switch (storageDir.toString()) {
        case 'temporaryDirectory':
          directory = await getTemporaryDirectory();
          break;

        case 'applicationDocumentsDirectory':
          directory = await getApplicationDocumentsDirectory();
          break;

        case 'externalStorageDirectory':
          directory = await getExternalStorageDirectory();
          break;
      }
    }

    // Directory + folder name
    final Directory directoryFolder =
        Directory('${directory!.path}/$folderName/');

    if (await directoryFolder.exists()) {
      // If folder already exists return path
      debugPrint('Exists');
      return directoryFolder.path;
    } else {
      debugPrint('Creating');
      // If folder does not exists create folder and then return its path
      final Directory directoryNewFolder =
          await directoryFolder.create(recursive: true);
      return directoryNewFolder.path;
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
        final thumbnail = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
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
    final gifFile = File(outputGifPath);
    await gifFile.writeAsBytes(gifBytes.toList());

    return gifFile.path;
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
  /// The `@required` parameter [onSave] is a callback Function that helps to
  /// retrieve the output path as the processing is complete. Returns a `String`.
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
    final String videoPath = currentVideoFile!.path;
    final String videoName = basename(videoPath).split('.')[0];
    final String fileExtension =
        outputType == OutputType.gif ? '.gif' : extension(videoPath);

    // Formatting Date and Time
    String dateTime = DateFormat.yMMMd()
        .addPattern('-')
        .add_Hms()
        .format(DateTime.now())
        .toString();

    String outputPath;
    String formattedDateTime = dateTime.replaceAll(' ', '');

    debugPrint("DateTime: $dateTime");
    debugPrint("Formatted: $formattedDateTime");

    videoFolderName ??= "Trimmer";
    videoFileName ??= "${videoName}_trimmed:$formattedDateTime";
    videoFileName = videoFileName.replaceAll(' ', '_');

    String path = await _createFolderInAppDocDir(
      videoFolderName,
      storageDir,
    ).whenComplete(() => debugPrint("Retrieved Trimmer folder"));

    Duration startPoint = Duration(milliseconds: startValue.toInt());
    Duration endPoint = Duration(milliseconds: endValue.toInt());

    // Checking the start and end point strings
    debugPrint("Start: ${startPoint.toString()} & End: ${endPoint.toString()}");
    debugPrint(path);

    outputPath = '$path$videoFileName$fileExtension';

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
      await _videoTrimmer.loadVideo(currentVideoFile!.path);

      // Trim the video
      final trimmedPath = await _videoTrimmer.trimVideo(
        startTimeMs: startValue.toInt(),
        endTimeMs: endValue.toInt(),
      );

      // Copy the trimmed video to the output path
      await File(trimmedPath!).copy(outputPath);
      onSave(outputPath);
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
