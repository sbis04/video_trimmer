library video_trimmer;

import 'dart:io';
import 'package:path/path.dart';

import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/trim_editor.dart';

/// Flutter Video Trimmer.
class Trimmer {
  File _videoFile;

  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

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

  Future<void> saveTrimmedVideo({
    @required double startValue,
    @required double endValue,
    String videoFolderName,
    String videoFileName,
  }) async {
    final String _videoPath = _videoFile.path;
    final String _videoName = basename(_videoPath).split('.')[0];

    // TODO: Take the video file name from the user --> DONE
    // TODO: Take the folder name to store the file --> DONE

    // TODO: Add a limit to maximum video length (property in package)

    if (videoFolderName == null) {
      videoFolderName = "Trimmer";
    }

    if (videoFileName == null) {
      videoFileName = _videoName;
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

    // Formatting Date and Time
    String dateTime = DateFormat.yMMMd()
        .addPattern('-')
        .add_Hms()
        .format(DateTime.now())
        .toString();

    String formattedDateTime = dateTime.replaceAll(' ', '');

    print("DateTime: $dateTime");
    print("Formatted: $formattedDateTime");

    _flutterFFmpeg
        .execute(
            '-i $_videoPath -ss ${startPoint.toString()} -t ${(endPoint - startPoint).toString()} -c copy $path${videoFileName}_trimmed:$formattedDateTime.mp4')
        .then((value) {
      print('Got value ');
    }).catchError((error) {
      print('Error');
    });
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
