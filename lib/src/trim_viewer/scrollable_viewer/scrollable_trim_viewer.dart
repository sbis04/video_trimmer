import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/trim_viewer/trim_editor_painter.dart';
import 'package:video_trimmer/src/trim_viewer/trim_area_properties.dart';
import 'package:video_trimmer/src/trim_viewer/trim_editor_properties.dart';
import 'package:video_trimmer/src/trim_viewer/trim_playback.dart';
import 'package:video_trimmer/src/trimmer.dart';
import 'package:video_trimmer/src/utils/duration_style.dart';

import '../../utils/editor_drag_type.dart';
import '../../utils/trim_drag.dart';
import '../../utils/initial_trim_range.dart';
import 'scrollable_thumbnail_viewer.dart';

/// Tolerance for comparing scroll offsets, which are doubles.
const double _kEps = 0.5;

/// Widget for displaying the video trimmer.
class ScrollableTrimViewer extends StatefulWidget {
  /// The Trimmer instance controlling the data.
  final Trimmer trimmer;

  /// For defining the total trimmer area width
  final double viewerWidth;

  /// For defining the total trimmer area height
  final double viewerHeight;

  /// For defining the maximum length of the output video.
  final Duration maxVideoLength;

  /// The shortest selection allowed. The handles stop rather than bring the
  /// frame closer together than this. Set it equal to [maxVideoLength] for a
  /// fixed-length selection that can only be moved. Defaults to no minimum.
  final Duration minVideoLength;

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

  /// The trim range to start with, in milliseconds: for example a range
  /// saved from [onChangeStart] / [onChangeEnd] earlier, so returning to the
  /// trimmer shows it again. Either can be given alone; the other is derived
  /// from [maxVideoLength]. Values are clamped to the video and to
  /// [maxVideoLength]. Leave both null for the default (the start of the
  /// video, as long as [maxVideoLength] allows).
  final double? initialStartValue;

  /// See [initialStartValue].
  final double? initialEndValue;

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
  /// duration text. By default it is set to `TextStyle(color: Colors.white)`.
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
    this.minVideoLength = Duration.zero,
    required this.onThumbnailLoadingComplete,
    this.initialStartValue,
    this.initialEndValue,
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
  String? get _videoPath => widget.trimmer.currentVideoPath;

  double _videoStartPos = 0.0;
  double _videoEndPos = 0.0;

  Offset _startPos = const Offset(0, 0);
  Offset _endPos = const Offset(0, 0);

  double _startFraction = 0.0;
  double _endFraction = 1.0;

  int _videoDuration = 0;
  int _trimmerAreaDuration = 0;
  int _remainingDuration = 0;

  double _thumbnailViewerW = 0.0;
  double _thumbnailViewerH = 0.0;

  int _numberOfThumbnails = 0;

  late double _startCircleSize;
  late double _endCircleSize;
  late double _borderRadius;

  double? fraction;
  double? maxLengthPixels;

  /// [ScrollableTrimViewer.minVideoLength] in strip pixels.
  double minLengthPixels = 0;

  ScrollableThumbnailViewer? thumbnailWidget;

  /// Drives the scrubber from the player and confines playback to the trim
  /// range. Created once the video is initialized.
  TrimPlayback? _playback;

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

  /// Whether a trim handle is currently under the user's finger. Auto-scroll
  /// only runs while this is true.
  bool _isDragging = false;

  /// Whether the current gesture is panning the thumbnail strip rather than
  /// dragging the trim frame. Decided once, in [_onDragStart].
  bool _panningStrip = false;

  late final ScrollController _scrollController;
  double totalVideoLengthInPixels = 0.0;

  /// Drives auto-scrolling once per frame, so the strip glides instead of
  /// hopping. Replaces the periodic timers this used to run on.
  Ticker? _autoScrollTicker;

  /// Signed auto-scroll speed in logical pixels per second. Negative scrolls
  /// back towards the start of the video.
  double _autoScrollVelocity = 0.0;

  /// Ticker elapsed time at the previous frame, used to derive dt.
  Duration _lastTickerElapsed = Duration.zero;

  /// Pending [TrimAreaProperties.autoScrollStartDelay] timer, if any.
  Timer? _autoScrollDelayTimer;

  /// How far the strip has been scrolled, expressed as a duration into the
  /// video. Returns `0` before the strip has been laid out, or when the whole
  /// video already fits in the trim area.
  double _scrolledDurationOffset() {
    if (!_scrollController.hasClients) return 0.0;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return 0.0;
    return (position.pixels / position.maxScrollExtent) * _remainingDuration;
  }

  /// Derives the selected trim range from the handle positions plus how far
  /// the strip has scrolled. Both dragging and scrolling funnel through here,
  /// so the two can happen at once without fighting each other.
  void _recomputeTrimPositions() {
    if (_thumbnailViewerW <= 0) return;
    final durationOffset = _scrolledDurationOffset();

    _startFraction = _startPos.dx / _thumbnailViewerW;
    _endFraction = _endPos.dx / _thumbnailViewerW;

    _videoStartPos = (_trimmerAreaDuration * _startFraction) + durationOffset;
    _videoEndPos = (_trimmerAreaDuration * _endFraction) + durationOffset;

    widget.onChangeStart?.call(_videoStartPos);
    widget.onChangeEnd?.call(_videoEndPos);
  }

  /// Keeps the trim range in step with the strip, whether it moved because of
  /// auto-scroll or because the user dragged the strip directly.
  void _onScrollChanged() {
    if (!mounted) return;
    setState(_recomputeTrimPositions);
  }

  /// Re-evaluates whether a handle is inside an edge zone, and how fast the
  /// strip should be travelling as a result. Speed ramps with how far the
  /// handle is pushed in, which is what makes this feel continuous rather
  /// than stepped.
  void _updateAutoScroll() {
    if (!_isDragging || !_scrollController.hasClients) {
      _cancelAutoScroll();
      return;
    }

    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) {
      _cancelAutoScroll();
      return;
    }

    final zone = widget.areaProperties.autoScrollEdgeZone;
    final maxVelocity = widget.areaProperties.maxAutoScrollVelocity;
    if (zone <= 0 || maxVelocity <= 0) {
      _cancelAutoScroll();
      return;
    }

    final canScrollForward = position.pixels < position.maxScrollExtent - _kEps;
    final canScrollBack = position.pixels > _kEps;
    final forwardEdge = _thumbnailViewerW - zone;

    double velocity = 0.0;
    // The left handle can only pull the strip backwards and the right handle
    // only forwards; dragging the whole frame can do either.
    if (_dragType != EditorDragType.left &&
        _endPos.dx > forwardEdge &&
        canScrollForward) {
      final depth = ((_endPos.dx - forwardEdge) / zone).clamp(0.0, 1.0);
      velocity = maxVelocity * _autoScrollRamp(depth);
    } else if (_dragType != EditorDragType.right &&
        _startPos.dx < zone &&
        canScrollBack) {
      final depth = ((zone - _startPos.dx) / zone).clamp(0.0, 1.0);
      velocity = -maxVelocity * _autoScrollRamp(depth);
    }

    _setAutoScrollVelocity(velocity);
  }

  /// Maps edge-zone depth to a fraction of the maximum speed. Starts at a
  /// usable crawl the moment the zone is entered rather than at zero, then
  /// accelerates towards the edge.
  double _autoScrollRamp(double depth) =>
      0.18 + 0.82 * Curves.easeInCubic.transform(depth);

  void _setAutoScrollVelocity(double velocity) {
    if (velocity == 0.0) {
      _cancelAutoScroll();
      return;
    }
    _autoScrollVelocity = velocity;
    if (_autoScrollTicker?.isTicking ?? false) return;

    final delay = widget.areaProperties.autoScrollStartDelay;
    if (delay <= Duration.zero) {
      _startAutoScrollTicker();
    } else {
      _autoScrollDelayTimer ??= Timer(delay, () {
        _autoScrollDelayTimer = null;
        if (_autoScrollVelocity != 0.0) _startAutoScrollTicker();
      });
    }
  }

  void _startAutoScrollTicker() {
    final ticker = _autoScrollTicker;
    if (ticker == null || ticker.isTicking) return;
    _lastTickerElapsed = Duration.zero;
    ticker.start();
  }

  void _cancelAutoScroll() {
    _autoScrollDelayTimer?.cancel();
    _autoScrollDelayTimer = null;
    _autoScrollVelocity = 0.0;
    if (_autoScrollTicker?.isTicking ?? false) _autoScrollTicker!.stop();
  }

  /// Advances the strip by `velocity * dt` every frame. Using [ScrollController.jumpTo]
  /// here is deliberate: the motion is already smooth because it is
  /// recalculated each frame, and an animation would fight the next tick.
  void _onAutoScrollTick(Duration elapsed) {
    final dtMicros = (elapsed - _lastTickerElapsed).inMicroseconds;
    _lastTickerElapsed = elapsed;
    if (dtMicros <= 0 || _autoScrollVelocity == 0.0) return;
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final delta =
        _autoScrollVelocity * (dtMicros / Duration.microsecondsPerSecond);
    final target =
        (position.pixels + delta).clamp(0.0, position.maxScrollExtent);

    if ((target - position.pixels).abs() < _kEps) {
      // Reached one end of the strip, so there is nothing left to scroll.
      _cancelAutoScroll();
      return;
    }
    _scrollController.jumpTo(target);
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScrollChanged);
    _autoScrollTicker = createTicker(_onAutoScrollTick);
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
      var initialScrollFraction = 0.0;
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
        final trimAreaLength = _thumbnailViewerW;
        log('TRIM AREA LENGTH: $trimAreaLength');
        final thumbnailHeight = widget.viewerHeight;
        final numberOfThumbnailsInArea = trimAreaLength / thumbnailHeight;
        final numberOfThumbnailsTotal = (numberOfThumbnailsInArea *
                (totalDuration.inMilliseconds /
                    trimAreaDuration.inMilliseconds))
            .ceil();
        log('THUMBNAILS: in area=$numberOfThumbnailsInArea, total=$numberOfThumbnailsTotal');

        // find precise durations according to the number of thumbnails;
        // preciseTotalLength = numberOfThumbnailsTotal * thumbnailHeight
        // totalDuration => preciseTotalLength
        // areaDuration => (preciseTotalLength * areaDuration) / totalDuration
        _numberOfThumbnails = numberOfThumbnailsTotal;
        final thumbnailWidget = ScrollableThumbnailViewer(
          scrollController: _scrollController,
          videoPath: _videoPath!,
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
        // The scroll extent has to cover exactly what the visible area does
        // not. Using the nominal trimAreaDuration here instead left the last
        // (trimAreaDuration - preciseAreaDuration) of the clip unreachable,
        // since rounding the thumbnail count up makes the precise area
        // slightly shorter (#192, #223, #207).
        _remainingDuration =
            totalDuration.inMilliseconds - _trimmerAreaDuration;
        log('Remaining Duration: $_remainingDuration ms');
        log('preciseAreaDuration: $preciseAreaDuration');
        final trimmerFraction =
            maxVideoLength.inMilliseconds / preciseAreaDuration.inMilliseconds;
        log('trimmerFraction: $trimmerFraction');
        final trimmerCover = trimmerFraction * trimAreaLength;
        maxLengthPixels = trimmerCover;
        minLengthPixels = trimAreaLength *
            (widget.minVideoLength.inMilliseconds /
                preciseAreaDuration.inMilliseconds);

        final range = resolveInitialTrimRange(
          durationMs: totalDuration.inMilliseconds.toDouble(),
          maxLengthMs: maxVideoLength.inMilliseconds.toDouble(),
          minLengthMs: widget.minVideoLength.inMilliseconds.toDouble(),
          initialStart: widget.initialStartValue,
          initialEnd: widget.initialEndValue,
        );
        // Centre the range in the visible area, scroll the strip there, and
        // place the handles relative to that scroll. With no initial values
        // this is the old default: no scroll, frame from 0 to the cap.
        final areaMs = _trimmerAreaDuration.toDouble();
        final scrollMs =
            (range.start - (areaMs - (range.end - range.start)) / 2)
                .clamp(0.0, _remainingDuration.toDouble());
        initialScrollFraction =
            _remainingDuration > 0 ? scrollMs / _remainingDuration : 0.0;
        _startPos =
            Offset((range.start - scrollMs) / areaMs * trimAreaLength, 0);
        _endPos = Offset(
          (range.end - scrollMs) / areaMs * trimAreaLength,
          thumbnailHeight,
        );
        log('START: $_startPos, END: $_endPos, scroll: $scrollMs ms');

        _videoStartPos = range.start;
        _videoEndPos = range.end;
        widget.onChangeStart?.call(_videoStartPos);
        widget.onChangeEnd?.call(_videoEndPos);
        log('Video Selected Duration: ${_videoEndPos - _videoStartPos}');
      });
      videoPlayerController
          .seekTo(Duration(milliseconds: _videoStartPos.toInt()));
      if (initialScrollFraction > 0) {
        // The strip only has a scroll extent once it has been laid out.
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          final position = _scrollController.position;
          _scrollController
              .jumpTo(initialScrollFraction * position.maxScrollExtent);
        });
      }
    });
  }

  Future<void> _initializeVideoController() async {
    if (_videoPath == null) return;
    _playback?.dispose();
    _playback = TrimPlayback(
      player: videoPlayerController,
      vsync: this,
      range: () => (start: _videoStartPos, end: _videoEndPos),
      onPlayingChanged: (playing) =>
          widget.onChangePlaybackState?.call(playing),
      onFrame: () {
        if (mounted) setState(() {});
      },
    )..attach();

    videoPlayerController.setVolume(1.0);
    _videoDuration = videoPlayerController.value.duration.inMilliseconds;
  }

  /// Called when the user starts dragging the frame, on either side on the whole frame.
  /// Determine which [EditorDragType] is used.
  void _onDragStart(DragStartDetails details) {
    final dx = details.localPosition.dx;
    final tolerance = widget.editorProperties.sideTapSize.toDouble();
    final startDistance = (dx - _startPos.dx).abs();
    final endDistance = (dx - _endPos.dx).abs();

    _panningStrip = false;

    // Whichever handle is within reach wins, closest first. Slicing the frame
    // into zones instead used to hand edge grabs to `center`, which moved both
    // handles when the user meant to move one.
    if (startDistance <= tolerance || endDistance <= tolerance) {
      _dragType = startDistance <= endDistance
          ? EditorDragType.left
          : EditorDragType.right;
      _allowDrag = true;
    } else if (dx > _startPos.dx && dx < _endPos.dx) {
      _dragType = EditorDragType.center;
      _allowDrag = true;
    } else if (widget.areaProperties.allowManualScroll) {
      // Outside the frame, so pan the strip under it instead.
      _panningStrip = true;
      _allowDrag = true;
      _cancelStripFling();
    } else {
      log('Dragging is outside of frame, ignoring gesture...');
      _allowDrag = false;
      return;
    }

    _isDragging = !_panningStrip;
  }

  /// Moves the strip with the finger. Content follows the drag, so pulling
  /// right rewinds towards the start of the video.
  void _panStrip(double deltaDx) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    final target =
        (position.pixels - deltaDx).clamp(0.0, position.maxScrollExtent);
    if ((target - position.pixels).abs() < _kEps) return;
    _scrollController.jumpTo(target);
  }

  /// Carries the strip on after the finger lifts, so a flick glides to a stop
  /// instead of halting dead.
  void _flingStrip(double velocityDx) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (velocityDx.abs() < 50) return;

    // A quarter second of travel at the release velocity reads as natural
    // deceleration without overshooting the clip.
    final target = (position.pixels - velocityDx * 0.25)
        .clamp(0.0, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 1.0) return;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _cancelStripFling() {
    if (!_scrollController.hasClients) return;
    // Stop any in-flight fling by pinning the strip where it currently sits.
    _scrollController.jumpTo(_scrollController.position.pixels);
  }

  /// Called during dragging, only executed if [_allowDrag] was set to true in
  /// [_onDragStart].
  /// Makes sure the limits are respected.
  void _onDragUpdate(DragUpdateDetails details) {
    if (!_allowDrag) return;

    if (_panningStrip) {
      _panStrip(details.delta.dx);
      return;
    }

    if (_dragType != EditorDragType.right) {
      _startCircleSize = widget.editorProperties.circleSizeOnDrag;
    }
    if (_dragType != EditorDragType.left) {
      _endCircleSize = widget.editorProperties.circleSizeOnDrag;
    }
    // Only the x axis moves: the painter reads the positions' dy to place the
    // handles, so adding a diagonal drag's dy used to shift them vertically.
    final moved = clampTrimDrag(
      type: _dragType,
      start: _startPos.dx,
      end: _endPos.dx,
      dx: details.delta.dx,
      viewerWidth: _thumbnailViewerW,
      maxLength: maxLengthPixels!,
      minLength: minLengthPixels,
    );
    if (moved.start != _startPos.dx || moved.end != _endPos.dx) {
      _startPos = Offset(moved.start, _startPos.dy);
      _endPos = Offset(moved.end, _endPos.dy);
      if (_dragType != EditorDragType.right) _onStartDragged();
      if (_dragType != EditorDragType.left) _onEndDragged();
    }
    _updateAutoScroll();
    setState(() {});
  }

  void _onStartDragged() => _recomputeTrimPositions();

  void _onEndDragged() => _recomputeTrimPositions();

  /// Drag gesture ended, update UI accordingly.
  void _onDragEnd(DragEndDetails details) {
    log('onDragEnd');
    _isDragging = false;
    _cancelAutoScroll();

    if (_panningStrip) {
      _panningStrip = false;
      _flingStrip(details.velocity.pixelsPerSecond.dx);
      return;
    }

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

  /// The gesture was taken over or interrupted, so unwind the drag state.
  void _onDragCancel() {
    _isDragging = false;
    _panningStrip = false;
    _cancelAutoScroll();
    if (!mounted) return;
    setState(() {
      _startCircleSize = widget.editorProperties.circleSize;
      _endCircleSize = widget.editorProperties.circleSize;
    });
  }

  @override
  void dispose() {
    // Detach before pausing: pause() notifies listeners synchronously, and
    // dispose runs inside a locked build scope, so the listener's setState
    // (and the playback-state callback it fires) would throw.
    _playback?.dispose();
    videoPlayerController.pause();
    _autoScrollDelayTimer?.cancel();
    _autoScrollTicker?.dispose();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    // The controller belongs to the Trimmer, not to this widget, so it is
    // not disposed here. Rebuilding or replacing the viewer used to kill the
    // shared controller and leave every other widget with a dead player.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                              Duration(milliseconds: _playback?.positionMs ?? 0)
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
        NotificationListener<ScrollEndNotification>(
          // A manual scroll of the strip moves the selection, so bring the
          // preview along with it. Handle drags seek in `_onDragEnd` instead,
          // and auto-scroll fires this every frame, so both are excluded.
          onNotification: (_) {
            if (!_isDragging) {
              videoPlayerController
                  .seekTo(Duration(milliseconds: _videoStartPos.toInt()));
            }
            return false;
          },
          child: GestureDetector(
            // Opaque because everything below is wrapped in IgnorePointer:
            // this detector owns the strip's gestures outright and routes each
            // one to either the trim frame or a strip pan.
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            onHorizontalDragCancel: _onDragCancel,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  foregroundPainter: TrimEditorPainter(
                    startPos: _startPos,
                    endPos: _endPos,
                    scrubberAnimationDx: _playback?.scrubberX(
                          startX: _startPos.dx,
                          endX: _endPos.dx,
                        ) ??
                        _startPos.dx,
                    startCircleSize: _startCircleSize,
                    endCircleSize: _endCircleSize,
                    borderRadius: _borderRadius,
                    borderWidth: widget.editorProperties.borderWidth,
                    scrubberWidth: widget.editorProperties.scrubberWidth,
                    circlePaintColor: widget.editorProperties.circlePaintColor,
                    handleStyle: widget.editorProperties.handleStyle,
                    handleHeight: widget.editorProperties.handleHeight,
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
                      // The blur and the edge chevrons are decoration only.
                      // Without IgnorePointer the icons swallow drags right
                      // where the user reaches to scroll the strip.
                      _scrollController.positions.isNotEmpty
                          ? IgnorePointer(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  gradient: widget.areaProperties.blurEdges
                                      ? LinearGradient(
                                          stops: const [0.0, 0.1, 0.9, 1.0],
                                          colors: [
                                            _scrollController.position.pixels ==
                                                    0.0
                                                ? Colors.transparent
                                                : widget
                                                    .areaProperties.blurColor,
                                            Colors.transparent,
                                            Colors.transparent,
                                            _scrollController.position.pixels ==
                                                    _scrollController.position
                                                        .maxScrollExtent
                                                ? Colors.transparent
                                                : widget
                                                    .areaProperties.blurColor,
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
                                            _scrollController.position.pixels !=
                                                    0.0
                                                ? 1.0
                                                : 0.0,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: widget.areaProperties.startIcon),
                                    const Spacer(),
                                    AnimatedOpacity(
                                      opacity:
                                          _scrollController.position.pixels !=
                                                  _scrollController
                                                      .position.maxScrollExtent
                                              ? 1.0
                                              : 0.0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: widget.areaProperties.endIcon,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
