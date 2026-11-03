import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

/// Which `TrimAreaProperties` constructor to build with. The three behave
/// differently enough to be worth switching between at runtime.
enum AreaPropertiesStyle {
  /// `TrimAreaProperties()` — the plain constructor.
  standard('Standard'),

  /// `TrimAreaProperties.fixed()` — no blur, no edge icons.
  fixed('Fixed'),

  /// `TrimAreaProperties.edgeBlur()` — blurred edges with chevrons.
  edgeBlur('Edge blur');

  const AreaPropertiesStyle(this.label);
  final String label;
}

/// Which widget to show at the ends of a scrollable trim area.
enum EdgeIconStyle {
  chevron('Chevron'),
  doubleChevron('Double chevron'),
  dot('Dot'),
  none('None');

  const EdgeIconStyle(this.label);
  final String label;
}

/// Every knob the package exposes, in one place, so the playground can rebuild
/// the whole trimmer from a single immutable value.
@immutable
class TrimmerConfig {
  const TrimmerConfig({
    // Viewer
    this.viewerType = ViewerType.auto,
    this.viewerHeight = 50.0,
    this.maxVideoLengthSeconds = 10,
    this.minVideoLengthSeconds = 0,
    this.paddingFraction = 0.2,
    this.showDuration = true,
    this.durationStyle = DurationStyle.FORMAT_MM_SS,
    this.durationTextColor = Colors.white,
    this.durationFontSize = 14.0,
    this.durationBold = false,
    // Editor
    this.circleSize = 5.0,
    this.circleSizeOnDrag = 8.0,
    this.borderWidth = 4.0,
    this.scrubberWidth = 1.0,
    this.editorBorderRadius = 5.0,
    this.circlePaintColor = const Color(0xFFF9A825),
    this.borderPaintColor = Colors.yellow,
    this.scrubberPaintColor = Colors.white,
    this.sideTapSize = 24,
    // Area
    this.areaStyle = AreaPropertiesStyle.edgeBlur,
    this.thumbnailFit = BoxFit.cover,
    this.thumbnailQuality = 50,
    this.blurEdges = true,
    this.blurColor = Colors.black,
    this.edgeIconStyle = EdgeIconStyle.chevron,
    this.areaBorderRadius = 4.0,
    // Scrolling
    this.allowManualScroll = true,
    this.autoScrollEdgeZone = 48.0,
    this.maxAutoScrollVelocity = 600.0,
    this.autoScrollStartDelayMs = 0,
    // Video viewer
    this.videoBorderColor = Colors.transparent,
    this.videoBorderWidth = 0.0,
    this.videoPadding = 0.0,
    // Output
    this.outputType = OutputType.video,
    this.fpsGIF = 10,
    this.scaleGIF = 480,
    this.qualityGIF = 50,
    this.storageDirIndex = 1,
    this.videoFolderName = 'Trimmer',
    this.customFileName = '',
    // Callbacks
    this.attachCallbacks = true,
  });

  // ---- Viewer ----
  final ViewerType viewerType;
  final double viewerHeight;
  final int maxVideoLengthSeconds;
  final int minVideoLengthSeconds;
  final double paddingFraction;
  final bool showDuration;
  final DurationStyle durationStyle;
  final Color durationTextColor;
  final double durationFontSize;
  final bool durationBold;

  // ---- Trim editor ----
  final double circleSize;
  final double circleSizeOnDrag;
  final double borderWidth;
  final double scrubberWidth;
  final double editorBorderRadius;
  final Color circlePaintColor;
  final Color borderPaintColor;
  final Color scrubberPaintColor;
  final int sideTapSize;

  // ---- Trim area ----
  final AreaPropertiesStyle areaStyle;
  final BoxFit thumbnailFit;
  final int thumbnailQuality;
  final bool blurEdges;
  final Color blurColor;
  final EdgeIconStyle edgeIconStyle;
  final double areaBorderRadius;

  // ---- Scrolling ----
  final bool allowManualScroll;
  final double autoScrollEdgeZone;
  final double maxAutoScrollVelocity;
  final int autoScrollStartDelayMs;

  // ---- Video viewer ----
  final Color videoBorderColor;
  final double videoBorderWidth;
  final double videoPadding;

  // ---- Output ----
  final OutputType outputType;
  final int fpsGIF;
  final int scaleGIF;
  final int qualityGIF;
  final int storageDirIndex;
  final String videoFolderName;
  final String customFileName;

  /// When false, `TrimViewer` is built with all three optional callbacks left
  /// off — the case that used to throw a null check error.
  final bool attachCallbacks;

  Duration get maxVideoLength => Duration(seconds: maxVideoLengthSeconds);

  /// Never above [maxVideoLength], which TrimViewer asserts.
  Duration get minVideoLength => Duration(
      seconds: minVideoLengthSeconds < maxVideoLengthSeconds
          ? minVideoLengthSeconds
          : maxVideoLengthSeconds);

  Duration get autoScrollStartDelay =>
      Duration(milliseconds: autoScrollStartDelayMs);

  StorageDir get storageDir => StorageDir.values[storageDirIndex];

  TextStyle get durationTextStyle => TextStyle(
        color: durationTextColor,
        fontSize: durationFontSize,
        fontWeight: durationBold ? FontWeight.bold : FontWeight.normal,
      );

  Widget? get startIcon => switch (edgeIconStyle) {
        EdgeIconStyle.chevron => const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 16),
        EdgeIconStyle.doubleChevron => const Icon(
            Icons.keyboard_double_arrow_left_rounded,
            color: Colors.white,
            size: 18),
        EdgeIconStyle.dot =>
          const Icon(Icons.circle, color: Colors.white70, size: 8),
        EdgeIconStyle.none => null,
      };

  Widget? get endIcon => switch (edgeIconStyle) {
        EdgeIconStyle.chevron => const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white, size: 16),
        EdgeIconStyle.doubleChevron => const Icon(
            Icons.keyboard_double_arrow_right_rounded,
            color: Colors.white,
            size: 18),
        EdgeIconStyle.dot =>
          const Icon(Icons.circle, color: Colors.white70, size: 8),
        EdgeIconStyle.none => null,
      };

  TrimEditorProperties get editorProperties => TrimEditorProperties(
        circleSize: circleSize,
        circleSizeOnDrag: circleSizeOnDrag,
        borderWidth: borderWidth,
        scrubberWidth: scrubberWidth,
        borderRadius: editorBorderRadius,
        circlePaintColor: circlePaintColor,
        borderPaintColor: borderPaintColor,
        scrubberPaintColor: scrubberPaintColor,
        sideTapSize: sideTapSize,
      );

  TrimAreaProperties get areaProperties => switch (areaStyle) {
        AreaPropertiesStyle.standard => TrimAreaProperties(
            thumbnailFit: thumbnailFit,
            thumbnailQuality: thumbnailQuality,
            blurEdges: blurEdges,
            blurColor: blurColor,
            startIcon: startIcon,
            endIcon: endIcon,
            borderRadius: areaBorderRadius,
            allowManualScroll: allowManualScroll,
            autoScrollEdgeZone: autoScrollEdgeZone,
            maxAutoScrollVelocity: maxAutoScrollVelocity,
            autoScrollStartDelay: autoScrollStartDelay,
          ),
        AreaPropertiesStyle.fixed => TrimAreaProperties.fixed(
            thumbnailFit: thumbnailFit,
            thumbnailQuality: thumbnailQuality,
            borderRadius: areaBorderRadius,
          ),
        AreaPropertiesStyle.edgeBlur => TrimAreaProperties.edgeBlur(
            thumbnailFit: thumbnailFit,
            thumbnailQuality: thumbnailQuality,
            blurEdges: blurEdges,
            blurColor: blurColor,
            startIcon: startIcon,
            endIcon: endIcon,
            borderRadius: areaBorderRadius,
            allowManualScroll: allowManualScroll,
            autoScrollEdgeZone: autoScrollEdgeZone,
            maxAutoScrollVelocity: maxAutoScrollVelocity,
            autoScrollStartDelay: autoScrollStartDelay,
          ),
      };

  TrimmerConfig copyWith({
    ViewerType? viewerType,
    double? viewerHeight,
    int? maxVideoLengthSeconds,
    int? minVideoLengthSeconds,
    double? paddingFraction,
    bool? showDuration,
    DurationStyle? durationStyle,
    Color? durationTextColor,
    double? durationFontSize,
    bool? durationBold,
    double? circleSize,
    double? circleSizeOnDrag,
    double? borderWidth,
    double? scrubberWidth,
    double? editorBorderRadius,
    Color? circlePaintColor,
    Color? borderPaintColor,
    Color? scrubberPaintColor,
    int? sideTapSize,
    AreaPropertiesStyle? areaStyle,
    BoxFit? thumbnailFit,
    int? thumbnailQuality,
    bool? blurEdges,
    Color? blurColor,
    EdgeIconStyle? edgeIconStyle,
    double? areaBorderRadius,
    bool? allowManualScroll,
    double? autoScrollEdgeZone,
    double? maxAutoScrollVelocity,
    int? autoScrollStartDelayMs,
    Color? videoBorderColor,
    double? videoBorderWidth,
    double? videoPadding,
    OutputType? outputType,
    int? fpsGIF,
    int? scaleGIF,
    int? qualityGIF,
    int? storageDirIndex,
    String? videoFolderName,
    String? customFileName,
    bool? attachCallbacks,
  }) {
    return TrimmerConfig(
      viewerType: viewerType ?? this.viewerType,
      viewerHeight: viewerHeight ?? this.viewerHeight,
      maxVideoLengthSeconds:
          maxVideoLengthSeconds ?? this.maxVideoLengthSeconds,
      minVideoLengthSeconds:
          minVideoLengthSeconds ?? this.minVideoLengthSeconds,
      paddingFraction: paddingFraction ?? this.paddingFraction,
      showDuration: showDuration ?? this.showDuration,
      durationStyle: durationStyle ?? this.durationStyle,
      durationTextColor: durationTextColor ?? this.durationTextColor,
      durationFontSize: durationFontSize ?? this.durationFontSize,
      durationBold: durationBold ?? this.durationBold,
      circleSize: circleSize ?? this.circleSize,
      circleSizeOnDrag: circleSizeOnDrag ?? this.circleSizeOnDrag,
      borderWidth: borderWidth ?? this.borderWidth,
      scrubberWidth: scrubberWidth ?? this.scrubberWidth,
      editorBorderRadius: editorBorderRadius ?? this.editorBorderRadius,
      circlePaintColor: circlePaintColor ?? this.circlePaintColor,
      borderPaintColor: borderPaintColor ?? this.borderPaintColor,
      scrubberPaintColor: scrubberPaintColor ?? this.scrubberPaintColor,
      sideTapSize: sideTapSize ?? this.sideTapSize,
      areaStyle: areaStyle ?? this.areaStyle,
      thumbnailFit: thumbnailFit ?? this.thumbnailFit,
      thumbnailQuality: thumbnailQuality ?? this.thumbnailQuality,
      blurEdges: blurEdges ?? this.blurEdges,
      blurColor: blurColor ?? this.blurColor,
      edgeIconStyle: edgeIconStyle ?? this.edgeIconStyle,
      areaBorderRadius: areaBorderRadius ?? this.areaBorderRadius,
      allowManualScroll: allowManualScroll ?? this.allowManualScroll,
      autoScrollEdgeZone: autoScrollEdgeZone ?? this.autoScrollEdgeZone,
      maxAutoScrollVelocity:
          maxAutoScrollVelocity ?? this.maxAutoScrollVelocity,
      autoScrollStartDelayMs:
          autoScrollStartDelayMs ?? this.autoScrollStartDelayMs,
      videoBorderColor: videoBorderColor ?? this.videoBorderColor,
      videoBorderWidth: videoBorderWidth ?? this.videoBorderWidth,
      videoPadding: videoPadding ?? this.videoPadding,
      outputType: outputType ?? this.outputType,
      fpsGIF: fpsGIF ?? this.fpsGIF,
      scaleGIF: scaleGIF ?? this.scaleGIF,
      qualityGIF: qualityGIF ?? this.qualityGIF,
      storageDirIndex: storageDirIndex ?? this.storageDirIndex,
      videoFolderName: videoFolderName ?? this.videoFolderName,
      customFileName: customFileName ?? this.customFileName,
      attachCallbacks: attachCallbacks ?? this.attachCallbacks,
    );
  }
}
