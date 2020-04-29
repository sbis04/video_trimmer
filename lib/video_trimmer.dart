library video_trimmer;

import 'dart:io';
import 'package:path/path.dart';

import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/file_formats.dart';
import 'package:video_trimmer/trim_editor.dart';

/// Helps in loading video from file, saving trimmed video to a file
/// and gives video playback controls. Some of the helpful methods
/// are:
/// * loadVideo()
/// * saveTrimmerVideo()
/// * videPlaybackControl()
class Trimmer {
  File _videoFile;

  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

  /// Loads a video from the file system.
  ///
  /// Returns the loaded video file.
  Future<File> loadVideo() async {
    File _video = await ImagePicker.pickVideo(source: ImageSource.gallery);
    if (_video != null) {
      _videoFile = _video;
      videoPlayerController = VideoPlayerController.file(_videoFile);
      await videoPlayerController.initialize().then((_) {});
      TrimEditor(
        viewerHeight: 50,
        viewerWidth: 50.0 * 8,
        videoFile: _videoFile,
      );
      return _video;
    }
    return _video;
  }

  Future<String> _createFolderInAppDocDir(String folderName) async {
    //Get this App Document Directory
    final Directory _appDocDir = await getExternalStorageDirectory();

    // print(_appDocDir.path);

    // return _appDocDir.path;

    // App Document Directory + folder name
    final Directory _appDocDirFolder =
        Directory('${_appDocDir.path}/$folderName/');

    // print(_appDocDirFolder.path);

    if (await _appDocDirFolder.exists()) {
      //if folder already exists return path
      print('Exists');
      return _appDocDirFolder.path;
    } else {
      print('Creating');
      //if folder not exists create folder and then return its path
      final Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      return _appDocDirNewFolder.path;
    }
  }

  /// Saves the trimmed video to file system.
  ///
  /// The required parameters are [startValue] & [endValue].
  ///
  /// The optional parameter [videoFolderName] is used to
  /// pass a folder name which will be used for creating a new
  /// folder in the selected directory. The default value for
  /// it is `Trimmer`.
  ///
  /// The optional parameter [videoFileName] is used for giving
  /// a new name to the trimmed video file. By default the
  /// trimmed video is named as `<original_file_name>_trimmed.mp4`.
  ///
  /// Also the video format available for saving is `mp4`.
  Future<String> saveTrimmedVideo({
    @required double startValue,
    @required double endValue,
    FileFormat outputFormat,
    int fpsGIF,
    int scaleGIF,
    String videoFolderName,
    String videoFileName,
  }) async {
    final String _videoPath = _videoFile.path;
    final String _videoName = basename(_videoPath).split('.')[0];
    // TODO: Add a limit to maximum video length (property in package)

    String _command;

    // Formatting Date and Time
    String dateTime = DateFormat.yMMMd()
        .addPattern('-')
        .add_Hms()
        .format(DateTime.now())
        .toString();

    String _resultString;
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

    String path = await _createFolderInAppDocDir(videoFolderName).whenComplete(
      () => print("Retrieved Trimmer folder"),
    );

    Duration startPoint = Duration(milliseconds: startValue.toInt());
    Duration endPoint = Duration(milliseconds: endValue.toInt());

    // Checking the start and end point strings
    print("Start: ${startPoint.toString()} & End: ${endPoint.toString()}");

    print(path);

    if (outputFormat == null) {
      outputFormat = FileFormat.mkv;
      print('OUTPUT: $outputFormat');
    }

    String _trimLengthCommand =
        '-i $_videoPath -ss $startPoint -t ${endPoint - startPoint}';

    _command = '$_trimLengthCommand -c copy ';

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

    _command += '$path$videoFileName$outputFormat';

    // '-i $_videoPath -ss ${startPoint.toString()} -t ${(endPoint - startPoint).toString()} -vf "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 $path$videoFileName.gif'
    await _flutterFFmpeg
        .execute(_command)
        .whenComplete(() {
      print('Got value');
      _resultString = 'Video successfuly saved';
    }).catchError((error) {
      print('Error');
      _resultString = 'Couldn\'t save the video';
    });

    return _resultString;
  }

  Future<bool> videPlaybackControl({
    @required double startValue,
    @required double endValue,
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

  File getVideoFile() {
    return _videoFile;
  }
}
