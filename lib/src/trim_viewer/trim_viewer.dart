import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

import 'fixed_viewer/fixed_trim_viewer.dart';
import 'scrollable_viewer/scrollable_trim_viewer.dart';

enum ViewerType {
  /// Automatically decide whether to use the
  /// fixed length or scrollable editor.
  auto,

  /// Use fixed length editor, `FixedTrimViewer`.
  fixed,

  /// Use scrollable editor, `ScrollableTrimViewer`.
  scrollable,
}

class TrimViewer extends StatefulWidget {
  /// The Trimmer instance controlling the data.
  final Trimmer trimmer;

  /// For defining the total trimmer area width
  final double viewerWidth;

  /// For defining the total trimmer area height
  final double viewerHeight;

  /// For specifying the type of the trim viewer.
  /// You can choose among: `auto`, `fixed`, and `scrollable`.
  ///
  /// **NOTE:** While using `scrollable` if the total video
  /// duration is less than maxVideoLength + padding, it
  /// will throw an error.
  ///
  /// By default it is set to `ViewerType.auto`.
  final ViewerType type;

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

  /// Widget for displaying the video trimmer.
  ///
  /// This has frame wise preview of the video with a
  /// slider for selecting the part of the video to be
  /// trimmed. It automatically selected whether to use
  /// `FixedTrimViewer` or `ScrollableTrimViewer`.
  ///
  /// If you want to use a specific kind of trim viewer, use
  /// the `type` property.
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
  /// * [type] for specifying the type of the trim viewer.
  ///
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
  ///
  /// * [editorProperties] defines properties for customizing the trim editor.
  ///
  ///
  /// * [areaProperties] defines properties for customizing the trim area.
  ///
  const TrimViewer({
    Key? key,
    required this.trimmer,
    required this.maxVideoLength,
    this.type = ViewerType.auto,
    this.viewerWidth = 50 * 8,
    this.viewerHeight = 50,
    this.showDuration = true,
    this.durationTextStyle = const TextStyle(color: Colors.white),
    this.onChangeStart,
    this.onChangeEnd,
    this.onChangePlaybackState,
    this.paddingFraction = 0.2,
    this.editorProperties = const TrimEditorProperties(),
    this.areaProperties = const TrimAreaProperties(),
  }) : super(key: key);

  @override
  State<TrimViewer> createState() => _TrimViewerState();
}

class _TrimViewerState extends State<TrimViewer> with TickerProviderStateMixin {
  bool? _isScrollableAllowed;

  @override
  void initState() {
    super.initState();
    widget.trimmer.eventStream.listen((event) {
      if (event == TrimmerEvent.initialized) {
        final totalDuration =
            widget.trimmer.videoPlayerController!.value.duration;
        final maxVideoLength = widget.maxVideoLength;
        final paddingFraction = widget.paddingFraction;
        final trimAreaDuration = Duration(
            milliseconds: (maxVideoLength.inMilliseconds +
                ((paddingFraction * maxVideoLength.inMilliseconds) * 2)
                    .toInt()));

        final shouldScroll = trimAreaDuration <= totalDuration;
        if (widget.type == ViewerType.scrollable && !shouldScroll) {
          throw 'Total video duration is less than maxVideoLength + padding. '
              'Can\'t use `ScrollableTrimViewer`. Change the type to `ViewerType.auto`.';
        }
        setState(() => _isScrollableAllowed = shouldScroll);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scrollableViewer = ScrollableTrimViewer(
      trimmer: widget.trimmer,
      maxVideoLength: widget.maxVideoLength,
      viewerWidth: widget.viewerWidth,
      viewerHeight: widget.viewerHeight,
      showDuration: widget.showDuration,
      durationTextStyle: widget.durationTextStyle,
      onChangeStart: widget.onChangeStart,
      onChangeEnd: widget.onChangeEnd,
      onChangePlaybackState: widget.onChangePlaybackState,
      paddingFraction: widget.paddingFraction,
      editorProperties: widget.editorProperties,
      areaProperties: widget.areaProperties,
    );

    final fixedTrimViewer = FixedTrimViewer(
      trimmer: widget.trimmer,
      maxVideoLength: widget.maxVideoLength,
      viewerWidth: widget.viewerWidth,
      viewerHeight: widget.viewerHeight,
      showDuration: widget.showDuration,
      durationTextStyle: widget.durationTextStyle,
      onChangeStart: widget.onChangeStart,
      onChangeEnd: widget.onChangeEnd,
      onChangePlaybackState: widget.onChangePlaybackState,
      editorProperties: widget.editorProperties,
      areaProperties: FixedTrimAreaProperties(
        thumbnailFit: widget.areaProperties.thumbnailFit,
        thumbnailQuality: widget.areaProperties.thumbnailQuality,
        borderRadius: widget.areaProperties.borderRadius,
      ),
    );

    return _isScrollableAllowed == null
        ? const SizedBox()
        : widget.type == ViewerType.fixed
            ? fixedTrimViewer
            : widget.type == ViewerType.scrollable
                ? scrollableViewer
                : _isScrollableAllowed == true
                    ? scrollableViewer
                    : fixedTrimViewer;
  }
}
