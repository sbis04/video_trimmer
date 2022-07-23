import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/thumbnail_viewer.dart';
import 'package:video_trimmer/src/trim_editor_painter.dart';
import 'package:video_trimmer/src/trimmer.dart';

class TrimEditor extends StatefulWidget {
  /// The Trimmer instance controlling the data.
  final Trimmer trimmer;

  /// For defining the total trimmer area width
  final double viewerWidth;

  /// For defining the total trimmer area height
  final double viewerHeight;

  /// For defining the image fit type of each thumbnail image.
  ///
  /// By default it is set to `BoxFit.fitHeight`.
  final BoxFit fit;

  /// For defining the maximum length of the output video.
  final Duration maxVideoLength;

  /// For specifying a size to the holder at the
  /// two ends of the video trimmer area, while it is `idle`.
  ///
  /// By default it is set to `5.0`.
  final double circleSize;

  /// For specifying the width of the border around
  /// the trim area. By default it is set to `3`.
  final double borderWidth;

  /// For specifying the width of the video scrubber
  final double scrubberWidth;

  /// For specifying a size to the holder at
  /// the two ends of the video trimmer area, while it is being
  /// `dragged`.
  ///
  /// By default it is set to `8.0`.
  final double circleSizeOnDrag;

  /// For specifying a color to the circle.
  ///
  /// By default it is set to `Colors.white`.
  final Color circlePaintColor;

  /// For specifying a color to the border of
  /// the trim area.
  ///
  /// By default it is set to `Colors.white`.
  final Color borderPaintColor;

  /// For specifying a color to the video
  /// scrubber inside the trim area.
  ///
  /// By default it is set to `Colors.white`.
  final Color scrubberPaintColor;

  /// For specifying the quality of each
  /// generated image thumbnail, to be displayed in the trimmer
  /// area.
  final int thumbnailQuality;

  /// For showing the start and the end point of the
  /// video on top of the trimmer area.
  ///
  /// By default it is set to `true`.
  final bool showDuration;

  /// For providing a `TextStyle` to the
  /// duration text.
  ///
  /// By default it is set to `TextStyle(color: Colors.white)`
  final TextStyle durationTextStyle;

  /// Callback to the video start position
  ///
  /// Returns the selected video start position in `milliseconds`.
  final Function(double startValue)? onChangeStart;

  /// Callback to the video end position.
  ///
  /// Returns the selected video end position in `milliseconds`.
  final Function(double endValue)? onChangeEnd;

  /// Callback to the video playback
  /// state to know whether it is currently playing or paused.
  ///
  /// Returns a `boolean` value. If `true`, video is currently
  /// playing, otherwise paused.
  final Function(bool isPlaying)? onChangePlaybackState;

  /// Determines the touch size of the side handles, left and right. The rest, in
  /// the center, will move the whole frame if [maxVideoLength] is inferior to the
  /// total duration of the video.
  final int sideTapSize;

  /// Widget for displaying the video trimmer.
  ///
  /// This has frame wise preview of the video with a
  /// slider for selecting the part of the video to be
  /// trimmed.
  ///
  /// The required parameters are [viewerWidth] & [viewerHeight]
  ///
  /// * [viewerWidth] to define the total trimmer area width.
  ///
  ///
  /// * [viewerHeight] to define the total trimmer area height.
  ///
  ///
  /// The optional parameters are:
  ///
  /// * [fit] for specifying the image fit type of each thumbnail image.
  /// By default it is set to `BoxFit.fitHeight`.
  ///
  ///
  /// * [maxVideoLength] for specifying the maximum length of the
  /// output video.
  ///
  ///
  /// * [circleSize] for specifying a size to the holder at the
  /// two ends of the video trimmer area, while it is `idle`.
  /// By default it is set to `5.0`.
  ///
  ///
  /// * [circleSizeOnDrag] for specifying a size to the holder at
  /// the two ends of the video trimmer area, while it is being
  /// `dragged`. By default it is set to `8.0`.
  ///
  ///
  /// * [circlePaintColor] for specifying a color to the circle.
  /// By default it is set to `Colors.white`.
  ///
  ///
  /// * [borderPaintColor] for specifying a color to the border of
  /// the trim area. By default it is set to `Colors.white`.
  ///
  ///
  /// * [scrubberPaintColor] for specifying a color to the video
  /// scrubber inside the trim area. By default it is set to
  /// `Colors.white`.
  ///
  ///
  /// * [thumbnailQuality] for specifying the quality of each
  /// generated image thumbnail, to be displayed in the trimmer
  /// area.
  ///
  ///
  /// * [showDuration] for showing the start and the end point of the
  /// video on top of the trimmer area. By default it is set to `true`.
  ///
  ///
  /// * [durationTextStyle] is for providing a `TextStyle` to the
  /// duration text. By default it is set to
  /// `TextStyle(color: Colors.white)`
  ///
  ///
  /// * [onChangeStart] is a callback to the video start position.
  ///
  ///
  /// * [onChangeEnd] is a callback to the video end position.
  ///
  ///
  /// * [onChangePlaybackState] is a callback to the video playback
  /// state to know whether it is currently playing or paused.
  ///
  const TrimEditor({
    Key? key,
    required this.trimmer,
    this.viewerWidth = 50.0 * 8,
    this.viewerHeight = 50,
    this.fit = BoxFit.fitHeight,
    this.maxVideoLength = const Duration(milliseconds: 0),
    this.circleSize = 5.0,
    this.borderWidth = 3,
    this.scrubberWidth = 1,
    this.circleSizeOnDrag = 8.0,
    this.circlePaintColor = Colors.white,
    this.borderPaintColor = Colors.white,
    this.scrubberPaintColor = Colors.white,
    this.thumbnailQuality = 75,
    this.showDuration = true,
    this.sideTapSize = 24,
    this.durationTextStyle = const TextStyle(color: Colors.white),
    this.onChangeStart,
    this.onChangeEnd,
    this.onChangePlaybackState,
  }) : super(key: key);

  @override
  _TrimEditorState createState() => _TrimEditorState();
}

class _TrimEditorState extends State<TrimEditor> with TickerProviderStateMixin {
  File? get _videoFile => widget.trimmer.currentVideoFile;

  Offset _startPos = const Offset(0, 0);
  Offset _endPos = const Offset(0, 0);

  double _startFraction = 0.0;
  double _endFraction = 1.0;

  int _videoDuration = 0;
  int _currentPosition = 0;

  double _thumbnailViewerW = 0.0;
  double _thumbnailViewerH = 0.0;

  int _numberOfThumbnails = 0;

  late double _circleSize;

  double? fraction;
  double? maxLengthPixels;

  ThumbnailViewer? thumbnailWidget;

  Animation<double>? _scrubberAnimation;
  AnimationController? _animationController;
  late Tween<double> _linearTween;

  /// Quick access to VideoPlayerController, only not null after [TrimmerEvent.initialized]
  /// has been emitted.
  VideoPlayerController get videoPlayerController =>
      widget.trimmer.videoPlayerController!;

  /// Keep track of the drag type, e.g. whether the user drags the left, center or
  /// right part of the frame. Set this in [_onDragStart] when the dragging starts.
  EditorDragType _dragType = EditorDragType.left;

  /// Whether the dragging is allowed. Dragging is ignore if the user's gesture is outside
  /// of the frame, to make the UI more realistic.
  bool _allowDrag = true;

  @override
  void initState() {
    super.initState();

    widget.trimmer.eventStream.listen((event) {
      if (event == TrimmerEvent.initialized) {
        //The video has been initialized, now we can load stuff

        _initializeVideoController();
        videoPlayerController.seekTo(const Duration(milliseconds: 0));
        setState(() {
          Duration totalDuration = videoPlayerController.value.duration;

          if (widget.maxVideoLength > const Duration(milliseconds: 0) &&
              widget.maxVideoLength < totalDuration) {
            if (widget.maxVideoLength < totalDuration) {
              fraction = widget.maxVideoLength.inMilliseconds /
                  totalDuration.inMilliseconds;

              maxLengthPixels = _thumbnailViewerW * fraction!;
            }
          } else {
            maxLengthPixels = _thumbnailViewerW;
          }

          widget.trimmer.videoEndPos = fraction != null
              ? _videoDuration.toDouble() * fraction!
              : _videoDuration.toDouble();

          widget.onChangeEnd!(widget.trimmer.videoEndPos);

          _endPos = Offset(
            maxLengthPixels != null ? maxLengthPixels! : _thumbnailViewerW,
            _thumbnailViewerH,
          );

          // Defining the tween points
          _linearTween = Tween(begin: _startPos.dx, end: _endPos.dx);
          _animationController = AnimationController(
            vsync: this,
            duration: Duration(
                milliseconds:
                    (widget.trimmer.videoEndPos - widget.trimmer.videoStartPos)
                        .toInt()),
          );

          _scrubberAnimation = _linearTween.animate(_animationController!)
            ..addListener(() {
              setState(() {});
            })
            ..addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                _animationController!.stop();
              }
            });
        });
      }
    });

    _circleSize = widget.circleSize;

    _thumbnailViewerH = widget.viewerHeight;

    _numberOfThumbnails = widget.viewerWidth ~/ _thumbnailViewerH;

    _thumbnailViewerW = _numberOfThumbnails * _thumbnailViewerH;
  }

  Future<void> _initializeVideoController() async {
    if (_videoFile != null) {
      videoPlayerController.addListener(() {
        final bool isPlaying = videoPlayerController.value.isPlaying;

        widget.onChangePlaybackState!(true);
        setState(() {
          _currentPosition =
              videoPlayerController.value.position.inMilliseconds;

          if (_currentPosition > widget.trimmer.videoEndPos.toInt()) {
            videoPlayerController.seekTo(
                Duration(milliseconds: widget.trimmer.videoStartPos.toInt()));
            widget.onChangePlaybackState!(false);
            _animationController!.reset();
          } else {
            if (!_animationController!.isAnimating) {
              widget.onChangePlaybackState!(true);
              _animationController!.forward();
            }
          }
        });
      });

      videoPlayerController.setVolume(1.0);
      _videoDuration = videoPlayerController.value.duration.inMilliseconds;

      final ThumbnailViewer _thumbnailWidget = ThumbnailViewer(
        videoFile: _videoFile!,
        videoDuration: _videoDuration,
        fit: widget.fit,
        thumbnailHeight: _thumbnailViewerH,
        numberOfThumbnails: _numberOfThumbnails,
        quality: widget.thumbnailQuality,
      );
      thumbnailWidget = _thumbnailWidget;
    }
  }

  /// Called when the user starts dragging the frame, on either side on the whole frame.
  /// Determine which [EditorDragType] is used.
  void _onDragStart(DragStartDetails details) {
    debugPrint("_onDragStart");
    debugPrint(details.localPosition.toString());
    debugPrint((_startPos.dx - details.localPosition.dx).abs().toString());
    debugPrint((_endPos.dx - details.localPosition.dx).abs().toString());

    final startDifference = _startPos.dx - details.localPosition.dx;
    final endDifference = _endPos.dx - details.localPosition.dx;

    //First we determine whether the dragging motion should be allowed. The allowed
    //zone is widget.sideTapSize (left) + frame (center) + widget.sideTapSize (right)
    if (startDifference <= widget.sideTapSize &&
        endDifference >= -widget.sideTapSize) {
      _allowDrag = true;
    } else {
      debugPrint("Dragging is outside of frame, ignoring gesture...");
      _allowDrag = false;
      return;
    }

    //Now we determine which part is dragged
    if (details.localPosition.dx <= _startPos.dx + widget.sideTapSize) {
      _dragType = EditorDragType.left;
    } else if (details.localPosition.dx <= _endPos.dx - widget.sideTapSize) {
      _dragType = EditorDragType.center;
    } else {
      _dragType = EditorDragType.right;
    }
  }

  /// Called during dragging, only executed if [_allowDrag] was set to true in
  /// [_onDragStart].
  /// Makes sure the limits are respected.
  void _onDragUpdate(DragUpdateDetails details) {
    if (!_allowDrag) return;

    _circleSize = widget.circleSizeOnDrag;

    if (_dragType == EditorDragType.left) {
      if ((_startPos.dx + details.delta.dx >= 0) &&
          (_startPos.dx + details.delta.dx <= _endPos.dx) &&
          !(_endPos.dx - _startPos.dx - details.delta.dx > maxLengthPixels!)) {
        _startPos += details.delta;
        _onStartDragged();
      }
    } else if (_dragType == EditorDragType.center) {
      if ((_startPos.dx + details.delta.dx >= 0) &&
          (_endPos.dx + details.delta.dx <= _thumbnailViewerW)) {
        _startPos += details.delta;
        _endPos += details.delta;
        _onStartDragged();
        _onEndDragged();
      }
    } else {
      if ((_endPos.dx + details.delta.dx <= _thumbnailViewerW) &&
          (_endPos.dx + details.delta.dx >= _startPos.dx) &&
          !(_endPos.dx - _startPos.dx + details.delta.dx > maxLengthPixels!)) {
        _endPos += details.delta;
        _onEndDragged();
      }
    }
    setState(() {});
  }

  void _onStartDragged() {
    _startFraction = (_startPos.dx / _thumbnailViewerW);
    widget.trimmer.videoStartPos = _videoDuration * _startFraction;
    widget.onChangeStart!(widget.trimmer.videoStartPos);
    _linearTween.begin = _startPos.dx;
    _animationController!.duration = Duration(
        milliseconds:
            (widget.trimmer.videoEndPos - widget.trimmer.videoStartPos)
                .toInt());
    _animationController!.reset();
  }

  void _onEndDragged() {
    _endFraction = _endPos.dx / _thumbnailViewerW;
    widget.trimmer.videoEndPos = _videoDuration * _endFraction;
    widget.onChangeEnd!(widget.trimmer.videoEndPos);
    _linearTween.end = _endPos.dx;
    _animationController!.duration = Duration(
        milliseconds:
            (widget.trimmer.videoEndPos - widget.trimmer.videoStartPos)
                .toInt());
    _animationController!.reset();
  }

  /// Drag gesture ended, update UI accordingly.
  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _circleSize = widget.circleSize;
      if (_dragType == EditorDragType.right) {
        videoPlayerController
            .seekTo(Duration(milliseconds: widget.trimmer.videoEndPos.toInt()));
      } else {
        videoPlayerController.seekTo(
            Duration(milliseconds: widget.trimmer.videoStartPos.toInt()));
      }
    });
  }

  @override
  void dispose() {
    videoPlayerController.pause();
    widget.onChangePlaybackState!(false);
    if (_videoFile != null) {
      videoPlayerController.setVolume(0.0);
      videoPlayerController.dispose();
      widget.onChangePlaybackState!(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          widget.showDuration
              ? SizedBox(
                  width: _thumbnailViewerW,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Text(
                          Duration(
                                  milliseconds:
                                      widget.trimmer.videoStartPos.toInt())
                              .toString()
                              .split('.')[0],
                          style: widget.durationTextStyle,
                        ),
                        videoPlayerController.value.isPlaying
                            ? Text(
                                Duration(milliseconds: _currentPosition.toInt())
                                    .toString()
                                    .split('.')[0],
                                style: widget.durationTextStyle,
                              )
                            : Container(),
                        Text(
                          Duration(
                                  milliseconds:
                                      widget.trimmer.videoEndPos.toInt())
                              .toString()
                              .split('.')[0],
                          style: widget.durationTextStyle,
                        ),
                      ],
                    ),
                  ),
                )
              : Container(),
          CustomPaint(
            foregroundPainter: TrimEditorPainter(
              startPos: _startPos,
              endPos: _endPos,
              scrubberAnimationDx: _scrubberAnimation?.value ?? 0,
              circleSize: _circleSize,
              borderWidth: widget.borderWidth,
              scrubberWidth: widget.scrubberWidth,
              circlePaintColor: widget.circlePaintColor,
              borderPaintColor: widget.borderPaintColor,
              scrubberPaintColor: widget.scrubberPaintColor,
            ),
            child: Container(
              color: Colors.grey[900],
              height: _thumbnailViewerH,
              width: _thumbnailViewerW,
              child: thumbnailWidget ?? Container(),
            ),
          ),
        ],
      ),
    );
  }
}

enum EditorDragType {
  /// The user is dragging the left part of the frame.
  left,

  /// The user is dragging the whole frame.
  center,

  /// The user is dragging the right part of the frame.
  right
}
