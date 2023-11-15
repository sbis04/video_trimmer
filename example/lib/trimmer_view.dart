import 'dart:io';

import 'package:example/core/constants.dart';
import 'package:example/loading_screen.dart';
import 'package:example/preview.dart';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

class TrimmerView extends StatefulWidget {
  final File file;

  const TrimmerView(this.file, {Key? key}) : super(key: key);
  @override
  State<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _trimmer.loadVideo(videoFile: widget.file);
    });
  }

  _saveVideo() {
    LoadingScreen(scaffoldGlobalKey).show();

    _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (outputPath) {
        LoadingScreen(scaffoldGlobalKey).hide();
        debugPrint('OUTPUT PATH: $outputPath');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Preview(outputPath),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).userGestureInProgress) {
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        key: scaffoldGlobalKey,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLighter,
          elevation: 1,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textColor,
            ),
          ),
          centerTitle: true,
          title: const Text(
            'Editar video',
            // L10n.of(context).textBackBtnPost,
            style: TextStyles.titlePost,
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.backgroundLighter,
                shadowColor: AppColors.backgroundLighter,
                elevation: 0,
              ),
              onPressed: () => _saveVideo(),
              child: const Icon(
                Icons.check,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: VideoViewer(trimmer: _trimmer),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TrimViewer(
                    trimmer: _trimmer,
                    viewerHeight: 90.0,
                    viewerWidth: MediaQuery.of(context).size.width,
                    durationStyle: DurationStyle.FORMAT_MM_SS,
                    durationTextStyle: const TextStyle(
                      color: AppColors.textColor,
                    ),
                    type: ViewerType.fixed,
                    editorProperties: const TrimEditorProperties(
                      borderPaintColor: AppColors.emphasisTextColor,
                      // borderWidth: 3,
                      // borderRadius: 4,
                      circlePaintColor: AppColors.accent,
                      // circleSize: 5.0,
                      // circleSizeOnDrag: 8.0,
                      // sideTapSize: 24,
                      // scrubberPaintColor: Colors.white,
                      scrubberWidth: 2.0,
                    ),
                    areaProperties: TrimAreaProperties.edgeBlur(
                      thumbnailQuality: 60,
                      borderRadius: 4,
                      // blurEdges: true,
                    ),
                    onChangeStart: (value) => _startValue = value,
                    onChangeEnd: (value) => _endValue = value,
                    onChangePlaybackState: (value) =>
                        setState(() => _isPlaying = value),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                child: _isPlaying
                    ? const Icon(
                        Icons.pause_rounded,
                        size: 80.0,
                        color: AppColors.mediumAccent,
                      )
                    : const Icon(
                        Icons.play_arrow_rounded,
                        size: 80.0,
                        color: AppColors.mediumAccent,
                      ),
                onPressed: () async {
                  bool playbackState = await _trimmer.videoPlaybackControl(
                    startValue: _startValue,
                    endValue: _endValue,
                  );
                  setState(() => _isPlaying = playbackState);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
