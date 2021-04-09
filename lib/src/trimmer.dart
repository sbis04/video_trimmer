import 'dart:io';
import 'package:path/path.dart';

import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/file_formats.dart';
import 'package:video_trimmer/src/storage_dir.dart';
import 'package:video_trimmer/src/trim_editor.dart';

/// Helps in loading video from file, saving trimmed video to a file
/// and gives video playback controls. Some of the helpful methods
/// are:
/// * [loadVideo()]
/// * [saveTrimmedVideo()]
/// * [videPlaybackControl()]
class Trimmer {
  static File? currentVideoFile;

  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

  /// Loads a video using the path provided.
  ///
  /// Returns the loaded video file.
  Future<void> loadVideo({required File videoFile}) async {
    currentVideoFile = videoFile;
    if (currentVideoFile != null) {
      videoPlayerController = VideoPlayerController.file(currentVideoFile!);
      await videoPlayerController.initialize().then((_) {
        TrimEditor(
          viewerHeight: 50,
          viewerWidth: 50.0 * 8,
          // currentVideoFile: currentVideoFile,
        );
      });
      // TrimEditor(
      //   viewerHeight: 50,
      //   viewerWidth: 50.0 * 8,
      //   // currentVideoFile: currentVideoFile,
      // );
    }
  }

  Future<String> _createFolderInAppDocDir(
    String folderName,
    StorageDir? storageDir,
  ) async {
    Directory? _directory;

    if (storageDir == null) {
      _directory = await getApplicationDocumentsDirectory();
    } else {
      switch (storageDir.toString()) {
        case 'temporaryDirectory':
          _directory = await getTemporaryDirectory();
          break;

        case 'applicationDocumentsDirectory':
          _directory = await getApplicationDocumentsDirectory();
          break;

        case 'externalStorageDirectory':
          _directory = await getExternalStorageDirectory();
          break;
      }
    }

    // Directory + folder name
    final Directory _directoryFolder =
        Directory('${_directory!.path}/$folderName/');

    if (await _directoryFolder.exists()) {
      // If folder already exists return path
      print('Exists');
      return _directoryFolder.path;
    } else {
      print('Creating');
      // If folder does not exists create folder and then return its path
      final Directory _directoryNewFolder =
          await _directoryFolder.create(recursive: true);
      return _directoryNewFolder.path;
    }
  }

  /// Saves the trimmed video to file system.
  ///
  /// Returns the output video path
  ///
  /// The required parameters are [startValue] & [endValue].
  ///
  /// The optional parameters are [videoFolderName], [videoFileName],
  /// [outputFormat], [fpsGIF], [scaleGIF], [applyVideoEncoding].
  ///
  /// The `@required` parameter [startValue] is for providing a starting point
  /// to the trimmed video. To be specified in `milliseconds`.
  ///
  /// The `@required` parameter [endValue] is for providing an ending point
  /// to the trimmed video. To be specified in `milliseconds`.
  ///
  /// The parameter [videoFolderName] is used to
  /// pass a folder name which will be used for creating a new
  /// folder in the selected directory. The default value for
  /// it is `Trimmer`.
  ///
  /// The parameter [videoFileName] is used for giving
  /// a new name to the trimmed video file. By default the
  /// trimmed video is named as `<original_file_name>_trimmed.mp4`.
  ///
  /// The parameter [outputFormat] is used for providing a
  /// file format to the trimmed video. This only accepts value
  /// of [FileFormat] type. By default it is set to `FileFormat.mp4`,
  /// which is for `mp4` files.
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
  ///
  /// * [applyVideoEncoding] for specifying whether to apply video
  /// encoding (by default it is set to `false`).
  ///
  ///
  /// ADVANCED OPTION:
  ///
  /// If you want to give custom `FFmpeg` command, then define
  /// [ffmpegCommand] & [customVideoFormat] strings. The `input path`,
  /// `output path`, `start` and `end` position is already define.
  ///
  /// NOTE: The advanced option does not provide any safety check, so if wrong
  /// video format is passed in [customVideoFormat], then the app may
  /// crash.
  ///
  Future<String> saveTrimmedVideo({
    required double startValue,
    required double endValue,
    bool applyVideoEncoding = false,
    FileFormat? outputFormat,
    String? ffmpegCommand,
    String? customVideoFormat,
    int? fpsGIF,
    int? scaleGIF,
    String? videoFolderName,
    String? videoFileName,
    StorageDir? storageDir,
  }) async {
    final String _videoPath = currentVideoFile!.path;
    final String _videoName = basename(_videoPath).split('.')[0];

    String _command;

    // Formatting Date and Time
    String dateTime = DateFormat.yMMMd()
        .addPattern('-')
        .add_Hms()
        .format(DateTime.now())
        .toString();

    // String _resultString;
    String _outputPath;
    String? _outputFormatString;
    String formattedDateTime = dateTime.replaceAll(' ', '');

    print("DateTime: $dateTime");
    print("Formatted: $formattedDateTime");

    if (videoFolderName == null) {
      videoFolderName = "Trimmer";
    }

    if (videoFileName == null) {
      videoFileName = "${_videoName}_trimmed:$formattedDateTime";
    }

    videoFileName = videoFileName.replaceAll(' ', '_');

    String path = await _createFolderInAppDocDir(
      videoFolderName,
      storageDir,
    ).whenComplete(
      () => print("Retrieved Trimmer folder"),
    );

    Duration startPoint = Duration(milliseconds: startValue.toInt());
    Duration endPoint = Duration(milliseconds: endValue.toInt());

    // Checking the start and end point strings
    print("Start: ${startPoint.toString()} & End: ${endPoint.toString()}");

    print(path);

    if (outputFormat == null) {
      outputFormat = FileFormat.mp4;
      _outputFormatString = outputFormat.toString();
      print('OUTPUT: $_outputFormatString');
    } else {
      _outputFormatString = outputFormat.toString();
    }

    String _trimLengthCommand =
        ' -ss $startPoint -i "$_videoPath" -t ${endPoint - startPoint} -avoid_negative_ts make_zero ';

    if (ffmpegCommand == null) {
      _command = '$_trimLengthCommand -c:a copy ';

      if (!applyVideoEncoding) {
        _command += '-c:v copy ';
      }

      if (outputFormat == FileFormat.gif) {
        if (fpsGIF == null) {
          fpsGIF = 10;
        }
        if (scaleGIF == null) {
          scaleGIF = 480;
        }
        _command =
            '$_trimLengthCommand -vf "fps=$fpsGIF,scale=$scaleGIF:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 ';
      }
    } else {
      _command = '$_trimLengthCommand $ffmpegCommand ';
      _outputFormatString = customVideoFormat;
    }

    _outputPath = '$path$videoFileName$_outputFormatString';

    _command += '"$_outputPath"';

    await _flutterFFmpeg.execute(_command).whenComplete(() {
      print('Got value');
      debugPrint('Video successfuly saved');
      // _resultString = 'Video successfuly saved';
    }).catchError((error) {
      print('Error');
      // _resultString = 'Couldn\'t save the video';
      debugPrint('Couldn\'t save the video');
    });

    return _outputPath;
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
    if (videoPlayerController.value.isPlaying) {
      await videoPlayerController.pause();
      return false;
    } else {
      if (videoPlayerController.value.position.inMilliseconds >=
          endValue.toInt()) {
        await videoPlayerController
            .seekTo(Duration(milliseconds: startValue.toInt()));
        await videoPlayerController.play();
        return true;
      } else {
        await videoPlayerController.play();
        return true;
      }
    }
  }

  File? getVideoFile() {
    return currentVideoFile;
  }
}
