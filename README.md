# Video Trimmer

A Flutter package for trimming videos.

#### Features

* Customizable video trimmer
* Video playback control
* Retrieving and storing video file

Also, supports conversion to **GIF**.


## Screenshots
<p align="center">
  <img width=300 src="https://github.com/sbis04/video_trimmer/raw/master/screenshots/trimmer_1.png" alt="Trimmer"/>
  <img width=300 src="https://github.com/sbis04/video_trimmer/raw/master/screenshots/trimmer_2.png" alt="Trimmer"/>
</p>

## Usage

* Add the dependency `video_trimmer` to your **pubspec.yaml** file.

### Android

* Go to `build.gradle` file in the path `<project root>/android/app/` and set the `minSdkVersion` to **24**:

   ```gradle
   minSdkVersion 24
   ```

### iOS

* Add the following keys to your **Info.plist** file, located in `<project root>/ios/Runner/Info.plist`:
  ```
  <key>NSCameraUsageDescription</key>
  <string>Used to demonstrate image picker plugin</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>Used to capture audio for image picker plugin</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>Used to demonstrate image picker plugin</string>
  ```

* Set the platform version in `ios/Podfile`:

   ```
   platform :ios, '9.3'
   ```

* Replace with the following in the `# Plugin Pods` section of the `ios/Podfile`: 

   ```
   # Prepare symlinks folder. We use symlinks to avoid having Podfile.lock
   # referring to absolute paths on developers' machines.

   system('rm -rf .symlinks')
   system('mkdir -p .symlinks/plugins')
   plugin_pods = parse_KV_file('../.flutter-plugins')
   plugin_pods.each do |name, path|
     symlink = File.join('.symlinks', 'plugins', name)
     File.symlink(path, symlink)
     if name == 'flutter_ffmpeg'
         pod name+'/full', :path => File.join(symlink, 'ios')
     else
         pod name, :path => File.join(symlink, 'ios')
     end
   end
   ```

## Functionalities

### Loading input video file

Returns the video file that was loaded.

```dart
final Trimmer _trimmer = Trimmer();
File _videoFile = await _trimmer.loadVideo();
```

### Saving trimmed video

Returns a string to indicate whether the saving operation was successful.

```dart
await _trimmer
    .saveTrimmedVideo(startValue: _startValue, endValue: _endValue)
    .then((value) {
  setState(() {
    _value = value;
  });
});
```

### Video playback state 

Returns the video playback state. If **true** then the video is playing, otherwise it is paused.

```dart
await _trimmer.videPlaybackControl(
  startValue: _startValue,
  endValue: _endValue,
);
```

### Advanced Command

You can use an advanced **FFmpeg** command if you require more customization. Just define your FFmpeg command using the `ffmpegCommand` property and set an output video format using `customVideoFormat`. 

Refer to the [Official FFmpeg Documentation](https://ffmpeg.org/documentation.html) for more information.

> **NOTE:** Passing a wrong video format to the `customVideoFormat` property may result in a crash.

```dart
// Example of defining a custom command

// This is already used for creating GIF by
// default, so you do not need to use this.

await _trimmer
    .saveTrimmedVideo(
        startValue: _startValue,
        endValue: _endValue,
        ffmpegCommand:
            '-vf "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0',
        customVideoFormat: '.gif')
    .then((value) {
  setState(() {
    _value = value;
  });
});
```

## Widgets

### Display a video playback area

```dart
VideoViewer()
```

### Display the video trimmer area

```dart
TrimEditor(
  viewerHeight: 50.0,
  viewerWidth: MediaQuery.of(context).size.width,
  videoFile: _file,
  onChangeStart: (value) {
    _startValue = value;
  },
  onChangeEnd: (value) {
    _endValue = value;
  },
  onChangePlaybackState: (value) {
    setState(() {
      _isPlaying = value;
    });
  },
),
```

## Example

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_trimmer/trim_editor.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:video_trimmer/video_viewer.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Trimmer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final Trimmer _trimmer = Trimmer();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Trimmer"),
      ),
      body: Center(
        child: Container(
          child: RaisedButton(
            child: Text("LOAD VIDEO"),
            onPressed: () async {
              File _videoFile = await _trimmer.loadVideo();
              if (_videoFile != null) {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return TrimmerView(_videoFile, _trimmer);
                }));
              }
            },
          ),
        ),
      ),
    );
  }
}

class TrimmerView extends StatefulWidget {
  final File _videoFile;
  final Trimmer _trimmer;
  TrimmerView(this._videoFile, this._trimmer);
  @override
  _TrimmerViewState createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  File _file;

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;

  @override
  void initState() {
    _file = widget._videoFile;
    super.initState();
  }

  Future<String> _saveVideo() async {
    setState(() {
      _progressVisibility = true;
    });

    String _value;

    await widget._trimmer
        .saveTrimmedVideo(startValue: _startValue, endValue: _endValue)
        .then((value) {
      setState(() {
        _progressVisibility = false;
        _value = value;
      });
    });

    return _value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Trimmer"),
      ),
      body: Builder(
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.only(bottom: 30.0),
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Visibility(
                  visible: _progressVisibility,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.red,
                  ),
                ),
                RaisedButton(
                  onPressed: _progressVisibility
                      ? null
                      : () async {
                          _saveVideo().then((value) {
                            final snackBar = SnackBar(content: Text(value));
                            Scaffold.of(context).showSnackBar(snackBar);
                          });
                        },
                  child: Text("SAVE"),
                ),
                Expanded(
                  child: VideoViewer(),
                ),
                Center(
                  child: TrimEditor(
                    viewerHeight: 50.0,
                    viewerWidth: MediaQuery.of(context).size.width,
                    videoFile: _file,
                    onChangeStart: (value) {
                      _startValue = value;
                    },
                    onChangeEnd: (value) {
                      _endValue = value;
                    },
                    onChangePlaybackState: (value) {
                      setState(() {
                        _isPlaying = value;
                      });
                    },
                  ),
                ),
                FlatButton(
                  child: _isPlaying
                      ? Icon(
                          Icons.pause,
                          size: 80.0,
                          color: Colors.white,
                        )
                      : Icon(
                          Icons.play_arrow,
                          size: 80.0,
                          color: Colors.white,
                        ),
                  onPressed: () async {
                    bool playbackState =
                        await widget._trimmer.videPlaybackControl(
                      startValue: _startValue,
                      endValue: _endValue,
                    );
                    setState(() {
                      _isPlaying = playbackState;
                    });
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```
