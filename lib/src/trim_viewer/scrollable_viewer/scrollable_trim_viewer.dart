import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/trim_viewer/trim_editor_painter.dart';
import 'package:video_trimmer/src/trim_viewer/trim_area_properties.dart';
import 'package:video_trimmer/src/trim_viewer/trim_editor_properties.dart';
import 'package:video_trimmer/src/trimmer.dart';
import 'package:video_trimmer/src/utils/duration_style.dart';

import '../../utils/editor_drag_type.dart';
import 'scrollable_thumbnail_viewer.dart';

class ScrollableTrimViewer extends StatefulWidget {
  /// The Trimmer instance controlling the data.
  final Trimmer trimmer;

  /// For defining the total trimmer area width
  final double viewerWidth;

  /// For defining the total trimmer area height
  final double viewerHeight;

  /// For defining the maximum length of the output video.
  final Duration maxVideoLength;

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

  /// For specifying a style of the duration
  ///
  /// By default it is set to `DurationStyle.FORMAT_HH_MM_SS`.
  final DurationStyle durationStyle;

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

  /// This is the fraction of padding present beside the trimmer editor,
  /// calculated on the `maxVideoLength` value.
  final double paddingFraction;

  /// Properties for customizing the trim editor.
  final TrimEditorProperties editorProperties;

  /// Properties for customizing the trim area.
  final TrimAreaProperties areaProperties;

  final VoidCallback onThumbnailLoadingComplete;

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
  /// * [maxVideoLength] for specifying the maximum length of the
  /// output video.
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
  ///
  /// * [editorProperties] defines properties for customizing the trim editor.
  ///
  ///
  /// * [areaProperties] defines properties for customizing the trim area.
  ///
  const ScrollableTrimViewer({
    super.key,
    required this.trimmer,
    required this.maxVideoLength,
    required this.onThumbnailLoadingComplete,
    this.viewerWidth = 50 * 8,
    this.viewerHeight = 50,
    this.showDuration = true,
    this.durationTextStyle = const TextStyle(color: Colors.white),
    this.durationStyle = DurationStyle.FORMAT_HH_MM_SS,
    this.onChangeStart,
    this.onChangeEnd,
    this.onChangePlaybackState,
    this.paddingFraction = 0.2,
    this.editorProperties = const TrimEditorProperties(),
    this.areaProperties = const TrimAreaProperties(),
  });

  @override
  State<ScrollableTrimViewer> createState() => _ScrollableTrimViewerState();
}

class _ScrollableTrimViewerState extends State<ScrollableTrimViewer>
    with TickerProviderStateMixin {
  final _trimmerAreaKey = GlobalKey();
  File? get _videoFile => widget.trimmer.currentVideoFile;

  double _videoStartPos = 0.0;
  double _videoEndPos = 0.0;

  double _localPosition = 0.0;

  Offset _startPos = const Offset(0, 0);
  Offset _endPos = const Offset(0, 0);

  double _startFraction = 0.0;
  double _endFraction = 1.0;

  int _videoDuration = 0;
  int _currentPosition = 0;
  int _trimmerAreaDuration = 0;
  int _remainingDuration = 0;

  double _thumbnailViewerW = 0.0;
  double _thumbnailViewerH = 0.0;

  int _numberOfThumbnails = 0;

  double _autoStartScrollPos = 0.0;
  double _autoEndScrollPos = 0.0;

  late double _startCircleSize;
  late double _endCircleSize;
  late double _borderRadius;

  double? fraction;
  double? maxLengthPixels;

  ScrollableThumbnailViewer? thumbnailWidget;

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

  late final ScrollController _scrollController;
  double scrollByValue = 10.0;
  double currentScrollValue = 0.0;
  double totalVideoLengthInPixels = 0.0;

  Timer? _scrollStartTimer;
  Timer? _scrollingTimer;

  void startScrolling(bool isTowardsEnd) {
    _scrollingTimer =
        Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        final midPoint = (_endPos.dx - _startPos.dx) / 2;
        var speedMultiplier = 1;
        if (isTowardsEnd) {
          if (_localPosition >= _endPos.dx) {
            speedMultiplier = 5;
          } else if (_localPosition > (midPoint + (midPoint * 2 / 3))) {
            speedMultiplier = 4;
          } else if (_localPosition > (midPoint + midPoint / 3)) {
            speedMultiplier = 2;
          }
          log('End scroll speed: ${speedMultiplier}x');
          if (_endPos.dx >= _autoEndScrollPos &&
              currentScrollValue <= totalVideoLengthInPixels) {
            currentScrollValue = math.min(
                currentScrollValue + scrollByValue * speedMultiplier,
                _numberOfThumbnails * _thumbnailViewerH);
          } else {
            _scrollingTimer?.cancel();
            return;
          }
        } else {
          if (_localPosition <= _startPos.dx) {
            speedMultiplier = 5;
          } else if (_localPosition < (midPoint - (midPoint * 2 / 3))) {
            speedMultiplier = 4;
          } else if (_localPosition < (midPoint - midPoint / 3)) {
            speedMultiplier = 2;
          }
          log('Start scroll speed: ${speedMultiplier}x');
          if (_startPos.dx <= _autoStartScrollPos && currentScrollValue != 0) {
            currentScrollValue = math.max(
                0, currentScrollValue - scrollByValue * speedMultiplier);
          } else {
            _scrollingTimer?.cancel();
            return;
          }
        }
        // log('scroll pixels: ${_scrollController.position.pixels}');
      });

      log('SCROLL: $currentScrollValue, (${((_scrollController.position.pixels / _scrollController.position.maxScrollExtent) * 100).toStringAsFixed(2)}%)');
      _scrollController.animateTo(
        currentScrollValue,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 100),
      );
      final durationChange = (_scrollController.position.pixels /
              _scrollController.position.maxScrollExtent) *
          _remainingDuration;
      _videoStartPos = (_trimmerAreaDuration * _startFraction) + durationChange;
      _videoEndPos = (_trimmerAreaDuration * _endFraction) + durationChange;
    });
    setState(() {});
  }

  void startTimer(bool isTowardsEnd) {
    var start = 300;
    _scrollStartTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (Timer timer) {
        if (start == 0) {
          timer.cancel();
          log('ANIMATE');
          if (_scrollingTimer?.isActive ?? false) return;
          startScrolling(isTowardsEnd);
        } else {
          start -= 100;
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startCircleSize = widget.editorProperties.circleSize;
    _endCircleSize = widget.editorProperties.circleSize;
    _borderRadius = widget.editorProperties.borderRadius;
    _thumbnailViewerH = widget.viewerHeight;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final renderBox =
          _trimmerAreaKey.currentContext?.findRenderObject() as RenderBox?;
      final trimmerActualWidth = renderBox?.size.width;
      log('RENDER BOX: ${renderBox?.size.width}');
      if (trimmerActualWidth == null) return;
      _thumbnailViewerW = trimmerActualWidth;
      _initializeVideoController();
      // The video has been initialized, now we can load stuff
      videoPlayerController.seekTo(const Duration(milliseconds: 0));
      setState(() {
        final totalDuration = videoPlayerController.value.duration;
        log('Total Video Length: $totalDuration');
        final maxVideoLength = widget.maxVideoLength;
        log('Max Video Length: $maxVideoLength');
        final paddingFraction = widget.paddingFraction;
        log('Padding Fraction: $paddingFraction');
        // trimAreaTime = maxVideoLength + (paddingFraction * maxVideoLength) * 2
        final trimAreaDuration = Duration(
            milliseconds: (maxVideoLength.inMilliseconds +
                ((paddingFraction * maxVideoLength.inMilliseconds) * 2)
                    .toInt()));
        log('Trim Area Duration: $trimAreaDuration');
        final remainingDuration = totalDuration - trimAreaDuration;
        log('Remaining Duration: $remainingDuration');
        _remainingDuration = remainingDuration.inMilliseconds;
        final trimAreaLength = _thumbnailViewerW;
        log('TRIM AREA LENGTH: $trimAreaLength');
        final autoScrollAreaLength = trimAreaLength * 0.02;
        log('autoScrollAreaLength: $autoScrollAreaLength');
        _autoStartScrollPos = autoScrollAreaLength;
        _autoEndScrollPos = trimAreaLength - autoScrollAreaLength;
        log('autoStartScrollPos: $_autoStartScrollPos, autoEndScrollPos: $_autoEndScrollPos');
        final thumbnailHeight = widget.viewerHeight;
        final numberOfThumbnailsInArea = trimAreaLength / thumbnailHeight;
        final numberOfThumbnailsTotal = (numberOfThumbnailsInArea *
                (totalDuration.inMilliseconds /
                    trimAreaDuration.inMilliseconds))
            .toInt();
        log('THUMBNAILS: in area=$numberOfThumbnailsInArea, total=$numberOfThumbnailsTotal');

        // find precise durations according to the number of thumbnails;
        // preciseTotalLength = numberOfThumbnailsTotal * thumbnailHeight
        // totalDuration => preciseTotalLength
        // areaDuration => (preciseTotalLength * areaDuration) / totalDuration
        _numberOfThumbnails = numberOfThumbnailsTotal;
        final thumbnailWidget = ScrollableThumbnailViewer(
          scrollController: _scrollController,
          videoFile: _videoFile!,
          videoDuration: _videoDuration,
          fit: widget.areaProperties.thumbnailFit,
          thumbnailHeight: _thumbnailViewerH,
          numberOfThumbnails: _numberOfThumbnails,
          quality: widget.areaProperties.thumbnailQuality,
          onThumbnailLoadingComplete: widget.onThumbnailLoadingComplete,
        );
        this.thumbnailWidget = thumbnailWidget;
        log('=========================');
        final preciseTotalLength = numberOfThumbnailsTotal * thumbnailHeight;
        log('preciseTotalLength: $preciseTotalLength');
        totalVideoLengthInPixels = preciseTotalLength - trimAreaLength;
        log('totalVideoLengthInPixels: $totalVideoLengthInPixels');
        final preciseAreaDuration = Duration(
            milliseconds: (totalDuration.inMilliseconds * trimAreaLength) ~/
                preciseTotalLength);
        _trimmerAreaDuration = preciseAreaDuration.inMilliseconds;
        log('preciseAreaDuration: $preciseAreaDuration');
        final trimmerFraction =
            maxVideoLength.inMilliseconds / preciseAreaDuration.inMilliseconds;
        log('trimmerFraction: $trimmerFraction');
        final trimmerCover = trimmerFraction * trimAreaLength;
        maxLengthPixels = trimmerCover;
        _endPos = Offset(trimmerCover, thumbnailHeight);
        log('START: $_startPos, END: $_endPos');

        _videoEndPos =
            preciseAreaDuration.inMilliseconds.toDouble() * trimmerFraction;
        log('Video End Pos: $_videoEndPos ms');
        widget.onChangeEnd!(_videoEndPos);
        log('Video Selected Duration: ${_videoEndPos - _videoStartPos}');

        // Defining the tween points
        _linearTween = Tween(begin: _startPos.dx, end: _endPos.dx);
        _animationController = AnimationController(
          vsync: this,
          duration:
              Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt()),
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
    });
  }

  Future<void> _initializeVideoController() async {
    if (_videoFile == null) return;
    videoPlayerController.addListener(() {
      final bool isPlaying = videoPlayerController.value.isPlaying;

      if (isPlaying) {
        widget.onChangePlaybackState!(true);
        setState(() {
          _currentPosition =
              videoPlayerController.value.position.inMilliseconds;

          if (_currentPosition > _videoEndPos.toInt()) {
            videoPlayerController.pause();
            widget.onChangePlaybackState!(false);
            _animationController!.stop();
          } else {
            if (!_animationController!.isAnimating) {
              widget.onChangePlaybackState!(true);
              _animationController!.forward();
            }
          }
        });
      } else {
        if (videoPlayerController.value.isInitialized) {
          if (_animationController != null) {
            if ((_scrubberAnimation?.value ?? 0).toInt() ==
                (_endPos.dx).toInt()) {
              _animationController!.reset();
            }
            _animationController!.stop();
            widget.onChangePlaybackState!(false);
          }
        }
      }
    });

    videoPlayerController.setVolume(1.0);
    _videoDuration = videoPlayerController.value.duration.inMilliseconds;
  }

  /// Called when the user starts dragging the frame, on either side on the whole frame.
  /// Determine which [EditorDragType] is used.
  void _onDragStart(DragStartDetails details) {
    log("onDragStart");
    log(details.localPosition.toString());
    log((_startPos.dx - details.localPosition.dx).abs().toString());
    log((_endPos.dx - details.localPosition.dx).abs().toString());

    final startDifference = _startPos.dx - details.localPosition.dx;
    final endDifference = _endPos.dx - details.localPosition.dx;

    // First we determine whether the dragging motion should be allowed. The allowed
    // zone is widget.sideTapSize (left) + frame (center) + widget.sideTapSize (right)
    if (startDifference <= widget.editorProperties.sideTapSize &&
        endDifference >= -widget.editorProperties.sideTapSize) {
      _allowDrag = true;
    } else {
      debugPrint("Dragging is outside of frame, ignoring gesture...");
      _allowDrag = false;
      return;
    }

    // Now we determine which part is dragged
    if (details.localPosition.dx <=
        _startPos.dx + widget.editorProperties.sideTapSize) {
      _dragType = EditorDragType.left;
    } else if (details.localPosition.dx <=
        _endPos.dx - widget.editorProperties.sideTapSize) {
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

    // log('Local pos: ${details.localPosition}');
    _localPosition = details.localPosition.dx;

    if (_dragType == EditorDragType.left) {
      _startCircleSize = widget.editorProperties.circleSizeOnDrag;
      if ((_startPos.dx + details.delta.dx >= 0) &&
          (_startPos.dx + details.delta.dx <= _endPos.dx) &&
          !(_endPos.dx - _startPos.dx - details.delta.dx > maxLengthPixels!)) {
        _startPos += details.delta;
        _onStartDragged();
      }
    } else if (_dragType == EditorDragType.center) {
      _startCircleSize = widget.editorProperties.circleSizeOnDrag;
      _endCircleSize = widget.editorProperties.circleSizeOnDrag;
      if ((_startPos.dx + details.delta.dx >= 0) &&
          (_endPos.dx + details.delta.dx <= _thumbnailViewerW)) {
        _startPos += details.delta;
        _endPos += details.delta;
        _onStartDragged();
        _onEndDragged();
      }
    } else {
      _endCircleSize = widget.editorProperties.circleSizeOnDrag;
      if ((_endPos.dx + details.delta.dx <= _thumbnailViewerW) &&
          (_endPos.dx + details.delta.dx >= _startPos.dx) &&
          !(_endPos.dx - _startPos.dx + details.delta.dx > maxLengthPixels!)) {
        _endPos += details.delta;
        _onEndDragged();
      }
    }
    // log('Video Duration :: Start: ${_videoStartPos / 1000}ms, End: ${_videoEndPos / 1000}ms');
    // log('UPDATE => START: ${_startPos.dx}, END: ${_endPos.dx}');
    _scrollStartTimer?.cancel();
    if (_endPos.dx >= _autoEndScrollPos &&
        currentScrollValue <= totalVideoLengthInPixels) {
      startTimer(true);
    } else if (_startPos.dx <= _autoStartScrollPos &&
        currentScrollValue != 0.0) {
      startTimer(false);
    }

    setState(() {});
  }

  void _onStartDragged() {
    if (_scrollingTimer?.isActive ?? false) return;
    _startFraction = (_startPos.dx / _thumbnailViewerW);
    _videoStartPos = (_trimmerAreaDuration * _startFraction) +
        (_scrollController.position.pixels /
                _scrollController.position.maxScrollExtent) *
            _remainingDuration;
    widget.onChangeStart!(_videoStartPos);
    _linearTween.begin = _startPos.dx;
    _animationController!.duration =
        Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt());
    _animationController!.reset();
  }

  void _onEndDragged() {
    if (_scrollingTimer?.isActive ?? false) return;
    _endFraction = _endPos.dx / _thumbnailViewerW;
    _videoEndPos = (_trimmerAreaDuration * _endFraction) +
        (_scrollController.position.pixels /
                _scrollController.position.maxScrollExtent) *
            _remainingDuration;
    widget.onChangeEnd!(_videoEndPos);
    _linearTween.end = _endPos.dx;
    _animationController!.duration =
        Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt());
    _animationController!.reset();
  }

  /// Drag gesture ended, update UI accordingly.
  void _onDragEnd(DragEndDetails details) {
    log('onDragEnd');
    _scrollStartTimer?.cancel();
    _scrollingTimer?.cancel();
    setState(() {
      _startCircleSize = widget.editorProperties.circleSize;
      _endCircleSize = widget.editorProperties.circleSize;
      if (_dragType == EditorDragType.right) {
        videoPlayerController
            .seekTo(Duration(milliseconds: _videoEndPos.toInt()));
      } else {
        videoPlayerController
            .seekTo(Duration(milliseconds: _videoStartPos.toInt()));
      }
    });
  }

  @override
  void dispose() {
    videoPlayerController.pause();
    _scrollController.dispose();
    _scrollStartTimer?.cancel();
    _scrollingTimer?.cancel();
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
                          Duration(milliseconds: _videoStartPos.toInt())
                              .format(widget.durationStyle),
                          style: widget.durationTextStyle,
                        ),
                        videoPlayerController.value.isPlaying
                            ? Text(
                                Duration(milliseconds: _currentPosition.toInt())
                                    .format(widget.durationStyle),
                                style: widget.durationTextStyle,
                              )
                            : Container(),
                        Text(
                          Duration(milliseconds: _videoEndPos.toInt())
                              .format(widget.durationStyle),
                          style: widget.durationTextStyle,
                        ),
                      ],
                    ),
                  ),
                )
              : Container(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                foregroundPainter: TrimEditorPainter(
                  startPos: _startPos,
                  endPos: _endPos,
                  scrubberAnimationDx: _scrubberAnimation?.value ?? 0,
                  startCircleSize: _startCircleSize,
                  endCircleSize: _endCircleSize,
                  borderRadius: _borderRadius,
                  borderWidth: widget.editorProperties.borderWidth,
                  scrubberWidth: widget.editorProperties.scrubberWidth,
                  circlePaintColor: widget.editorProperties.circlePaintColor,
                  borderPaintColor: widget.editorProperties.borderPaintColor,
                  scrubberPaintColor:
                      widget.editorProperties.scrubberPaintColor,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                          widget.areaProperties.borderRadius),
                      child: Container(
                        key: _trimmerAreaKey,
                        color: Colors.grey[900],
                        height: _thumbnailViewerH,
                        width: _thumbnailViewerW == 0.0
                            ? widget.viewerWidth
                            : _thumbnailViewerW,
                        child: thumbnailWidget ?? Container(),
                      ),
                    ),
                    _scrollController.positions.isNotEmpty
                        ? AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: widget.areaProperties.blurEdges
                                  ? LinearGradient(
                                      stops: const [0.0, 0.1, 0.9, 1.0],
                                      colors: [
                                        _scrollController.position.pixels == 0.0
                                            ? Colors.transparent
                                            : widget.areaProperties.blurColor,
                                        Colors.transparent,
                                        Colors.transparent,
                                        _scrollController.position.pixels ==
                                                _scrollController
                                                    .position.maxScrollExtent
                                            ? Colors.transparent
                                            : widget.areaProperties.blurColor,
                                      ],
                                    )
                                  : null,
                            ),
                            height: _thumbnailViewerH,
                            width: widget.viewerWidth,
                            child: Row(
                              children: [
                                AnimatedOpacity(
                                    opacity:
                                        _scrollController.position.pixels != 0.0
                                            ? 1.0
                                            : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: widget.areaProperties.startIcon),
                                const Spacer(),
                                AnimatedOpacity(
                                  opacity: _scrollController.position.pixels !=
                                          _scrollController
                                              .position.maxScrollExtent
                                      ? 1.0
                                      : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: widget.areaProperties.endIcon,
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
              // This widget is in development for making the DEBUGGING
              // process of this package easier
              Visibility(
                visible: false,
                child: Row(
                  children: [
                    Container(
                      color: Colors.red.withOpacity(0.6),
                      height: _thumbnailViewerH,
                      // 2% of total trimmer width
                      width: (_thumbnailViewerW == 0.0
                              ? widget.viewerWidth
                              : _thumbnailViewerW) *
                          0.02,
                    ),
                    const Spacer(),
                    Container(
                      color: Colors.red.withOpacity(0.6),
                      height: _thumbnailViewerH,
                      // 2% of total trimmer width
                      width: (_thumbnailViewerW == 0.0
                              ? widget.viewerWidth
                              : _thumbnailViewerW) *
                          0.02,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
