import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/thumbnail_viewer.dart';
import 'package:video_trimmer/trim_editor_painter.dart';
import 'package:video_trimmer/video_trimmer.dart';

VideoPlayerController videoPlayerController;

class TrimEditor extends StatefulWidget {
  final double viewerWidth;
  final double viewerHeight;
  final File videoFile;
  final Function(double startValue) onChangeStart;
  final Function(double endValue) onChangeEnd;
  final Function(bool isPlaying) onChangePlaybackState;

  TrimEditor({
    @required this.viewerWidth,
    @required this.viewerHeight,
    @required this.videoFile,
    this.onChangeStart,
    this.onChangeEnd,
    this.onChangePlaybackState,
  });

  @override
  _TrimEditorState createState() => _TrimEditorState();
}

class _TrimEditorState extends State<TrimEditor> {
  // Trimmer _trimmer;

  File _videoFile;

  double _videoStartPos = 0.0;
  double _videoEndPos = 0.0;

  bool _canUpdateStart = true;
  bool _isLeftDrag = true;

  Offset _startPos = Offset(0, 0);
  Offset _endPos = Offset(0, 0);
  Offset _currentPos = Offset(0, 0);

  double _startFraction = 0.0;
  double _endFraction = 1.0;

  int _videoDuration = 0;
  int _currentPosition = 0;

  double _thumbnailViewerW = 0.0;
  double _thumbnailViewerH = 0.0;

  // final double _thumbnailViewerW = 50.0 * 8;
  // final double _thumbnailViewerH = 50.0;

  double _circleSize = 5.0;

  ThumbnailViewer thumbnailWidget;

  Future<void> initializeVideoController() async {
    if (_videoFile != null) {
      videoPlayerController.addListener(() {
        final bool isPlaying = videoPlayerController.value.isPlaying;

        if (isPlaying) {
          widget.onChangePlaybackState(isPlaying);
          setState(() {
            _currentPosition =
                videoPlayerController.value.position.inMilliseconds;
            print("CURRENT POS: $_currentPosition");

            if (_currentPosition > _videoEndPos.toInt()) {
              videoPlayerController.pause();
              widget.onChangePlaybackState(false);
            }

            if (_currentPosition <= _videoEndPos.toInt()) {
              _currentPos = Offset(
                (_currentPosition / _videoDuration) * _thumbnailViewerW,
                0,
              );
            }
          });
        }
      });
      // videoPlayerController.pause();

      videoPlayerController.setVolume(1.0);
      _videoDuration = videoPlayerController.value.duration.inMilliseconds;
      print(_videoFile.path);

      _videoEndPos = _videoDuration.toDouble();
      widget.onChangeEnd(_videoEndPos);

      final ThumbnailViewer _thumbnailWidget =
          ThumbnailViewer(_videoFile, _videoDuration);
      thumbnailWidget = _thumbnailWidget;
      // widget.onChangePlaybackState(false);
    }
  }

  void _setVideoStartPosition(DragUpdateDetails details) {
    setState(() {
      _startPos += details.delta;
      _startFraction = (_startPos.dx / _thumbnailViewerW);
      print("START PERCENT: $_startFraction");
      _videoStartPos = _videoDuration * _startFraction;
      widget.onChangeStart(_videoStartPos);
      videoPlayerController
          .seekTo(Duration(milliseconds: _videoStartPos.toInt()));
    });
  }

  void _setVideoEndPosition(DragUpdateDetails details) {
    setState(() {
      _endPos += details.delta;
      _endFraction = _endPos.dx / _thumbnailViewerW;
      print("END PERCENT: $_endFraction");
      _videoEndPos = _videoDuration * _endFraction;
      widget.onChangeEnd(_videoEndPos);
      videoPlayerController
          .seekTo(Duration(milliseconds: _videoEndPos.toInt()));
    });
  }

  @override
  void initState() {
    super.initState();
    // _trimmer = Trimmer();
    _videoFile = widget.videoFile;
    _thumbnailViewerW = widget.viewerWidth;
    _thumbnailViewerH = widget.viewerHeight;

    _endPos = Offset(_thumbnailViewerW, _thumbnailViewerH);
    // _videoStartPos = _trimmer.getVideoStartPos();
    // _videoEndPos = _trimmer.getVideoEndPos();
    initializeVideoController();
  }

  @override
  void dispose() {
    videoPlayerController.pause();
    // widget.onChangePlaybackState(false);
    if (widget.videoFile != null) {
      videoPlayerController.setVolume(0.0);
      videoPlayerController.pause();
      widget.onChangePlaybackState(false);
      videoPlayerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        print("START");
        print(details.localPosition);
        print((_startPos.dx - details.localPosition.dx).abs());
        print((_endPos.dx - details.localPosition.dx).abs());

        if (_endPos.dx >= _startPos.dx) {
          if ((_startPos.dx - details.localPosition.dx).abs() >
              (_endPos.dx - details.localPosition.dx).abs()) {
            setState(() {
              _canUpdateStart = false;
            });
          } else {
            setState(() {
              _canUpdateStart = true;
            });
          }
        } else {
          if (_startPos.dx > details.localPosition.dx) {
            _isLeftDrag = true;
          } else {
            _isLeftDrag = false;
          }
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        setState(() {
          _circleSize = 5.0;
        });
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        print("UPDATE");
        print("START POINT: ${_startPos.dx + details.delta.dx}");
        print("END POINT: ${_endPos.dx + details.delta.dx}");

        _circleSize = 8.0;

        if (_endPos.dx >= _startPos.dx) {
          _isLeftDrag = false;
          if (_canUpdateStart && _startPos.dx + details.delta.dx > 0) {
            _isLeftDrag = false; // To prevent from scrolling over
            _setVideoStartPosition(details);
          } else if (!_canUpdateStart && _endPos.dx + details.delta.dx < 400) {
            _isLeftDrag = true; // To prevent from scrolling over
            _setVideoEndPosition(details);
          }
        } else {
          if (_isLeftDrag && _startPos.dx + details.delta.dx > 0) {
            _setVideoStartPosition(details);
          } else if (!_isLeftDrag && _endPos.dx + details.delta.dx < 400) {
            _setVideoEndPosition(details);
          }
        }
      },
      child: CustomPaint(
        foregroundPainter: TrimEditorPainter(
          startPos: _startPos,
          endPos: _endPos,
          currentPos: _currentPos,
          circleSize: _circleSize,
          circlePaintColor: Colors.purpleAccent,
          borderPaintColor: Colors.amber,
          scrubberPaintColor: Colors.black,
        ),
        child: Container(
          color: Colors.grey[900],
          height: _thumbnailViewerH,
          width: _thumbnailViewerW,
          child: thumbnailWidget == null ? Column() : thumbnailWidget,
        ),
      ),
    );
  }
}
