<a href="https://github.com/Solido/awesome-flutter">
   <img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square" />
</a>
<a href="https://pub.dev/packages/video_trimmer">
  <img alt="Pub Version" src="https://img.shields.io/pub/v/video_trimmer?style=flat-square">
</a>
<a href="https://github.com/sbis04/video_trimmer/stargazers">
  <img alt="GitHub stars" src="https://img.shields.io/github/stars/sbis04/video_trimmer?style=flat-square">
</a>
<a href="https://github.com/sbis04/video_trimmer/blob/master/LICENSE">
  <img alt="GitHub license" src="https://img.shields.io/github/license/sbis04/video_trimmer?style=flat-square">
</a>

<p align="center">
  <img src="https://github.com/sbis04/video_trimmer/raw/master/screenshots/cover.png" alt="Video Trimmer" />
</p>

<h4 align="center">A Flutter package for trimming videos</h4>

### Features

* Customizable video trimmer
* Video playback control
* Retrieving and storing video file

Also, supports conversion to **GIF**.

<h4 align="center">TRIM EDITOR</h4>

<p align="center">
  <img src="https://github.com/sbis04/video_trimmer/raw/master/screenshots/editor_demo.gif" alt="Trim Editor" />
</p>

<h4 align="center">EXAMPLE APP</h4>

<p align="center">
  <img src="https://github.com/sbis04/video_trimmer/raw/master/screenshots/trimmer.png" alt="Trimmer"/>
</p>

<h4 align="center">CUSTOMIZABLE VIDEO EDITOR</h4>

<p align="center">
  <img src="https://github.com/sbis04/video_trimmer/raw/master/screenshots/trim_editor.gif" alt="Trim Editor" />
</p>

## Usage

* Add the dependency `video_trimmer` to your **pubspec.yaml** file.

### Android

* Go to `<project root>/android/app/build.gradle` and set the proper `minSdkVersion`, **24** for **Main Release** or **16** for **LTS Release**. 
  
  > Refer to the [FFmpeg Release](#ffmpeg-release) section.

   ```gradle
   minSdkVersion <version>
   ```
* Go to `<project root>/android/build.gradle` and add the following line:

   ```gradle
   ext.flutterFFmpegPackage = '<package name>'
   ```

   > Replace the `<package name>` with a proper package name from the [Packages List](#packages-list) section.

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

* Set the platform version in `ios/Podfile`, **12.1** for **Main Release** or **9.3** for **LTS Release**.
  
  > Refer to the [FFmpeg Release](#ffmpeg-release) section.

   ```
   platform :ios, '<version>'
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
         pod name+'/<package name>', :path => File.join(symlink, 'ios')
     else
         pod name, :path => File.join(symlink, 'ios')
     end
   end
   ```

   > Replace the `<package name>` with a proper package name from the [Packages List](#packages-list) section.


### FFmpeg Release

In reference to the releases specified in the [flutter_ffmpeg](https://pub.dev/packages/flutter_ffmpeg) package.

<table>
<thead>
    <tr>
        <th align="center"></th>
        <th align="center">Main Release</th>
        <th align="center">LTS Release</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td align="center">Android API Level</td>
        <td align="center">24</td>
        <td align="center">16</td>
    </tr>
    <tr>
        <td align="center">Android Camera Access</td>
        <td align="center">Yes</td>
        <td align="center">-</td>
    </tr>
    <tr>
        <td align="center">Android Architectures</td>
        <td align="center">arm-v7a-neon<br>arm64-v8a<br>x86<br>x86-64</td>
        <td align="center">arm-v7a<br>arm-v7a-neon<br>arm64-v8a<br>x86<br>x86-64</td>
    </tr>
    <tr>
        <td align="center">Xcode Support</td>
        <td align="center">10.1</td>
        <td align="center">7.3.1</td>
    </tr>
    <tr>
        <td align="center">iOS SDK</td>
        <td align="center">12.1</td>
        <td align="center">9.3</td>
    </tr>
    <tr>
        <td align="center">iOS Architectures</td>
        <td align="center">arm64<br>arm64e<br>x86-64</td>
        <td align="center">armv7<br>arm64<br>i386<br>x86-64</td>
    </tr>
</tbody>
</table>

### Packages List

The following **FFmpeg Packages** List is in reference to the [flutter_ffmpeg](https://pub.dev/packages/flutter_ffmpeg) package.

| Package | Main Release | LTS Release |
| :----: | :----: | :----: |
| min | min  | min-lts |
| min-gpl | min-gpl | min-gpl-lts |
| https | https | https-lts |
| https-gpl | https-gpl | https-gpl-lts |
| audio | audio | audio-lts |
| video | video | video-lts |
| full | full | full-lts |
| full-gpl | full-gpl | full-gpl-lts |

## Functionalities

### Loading input video file

```dart
final Trimmer _trimmer = Trimmer();
await _trimmer.loadVideo(videoFile: file);
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
)
```

## Example

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
              File file = await ImagePicker.pickVideo(
                source: ImageSource.gallery,
              );
              if (file != null) {
                await _trimmer.loadVideo(videoFile: file);
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return TrimmerView(_trimmer);
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
  final Trimmer _trimmer;
  TrimmerView(this._trimmer);
  @override
  _TrimmerViewState createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;

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
                          _saveVideo().then((outputPath) {
                            print('OUTPUT PATH: $outputPath');
                            final snackBar = SnackBar(content: Text('Video Saved successfully'));
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

## License

Copyright (c) 2020 Souvik Biswas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
