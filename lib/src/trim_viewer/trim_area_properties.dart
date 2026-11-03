import 'package:flutter/material.dart';

class TrimAreaProperties {
  /// For defining the image fit type of each thumbnail image.
  ///
  /// By default it is set to `BoxFit.fitHeight`.
  final BoxFit thumbnailFit;

  /// For specifying the quality of each
  /// generated image thumbnail, to be displayed in the trimmer
  /// area.
  ///
  /// By default it is set to `75`.
  final int thumbnailQuality;

  /// For adding a blur to the trim area edges. Use `blurColor`
  /// for specifying the color of the blur (usually it's the
  /// background color which helps in blending).
  ///
  /// By default it is set to `false`.
  final bool blurEdges;

  /// For specifying the color of the blur. Use the color of the
  /// background to blend with it.
  ///
  /// By default it is set to `Colors.black`.
  final Color blurColor;

  /// For specifying the widget to be placed at the start
  /// of the trimmer area. You can pass `null` for hiding
  /// the widget.
  ///
  /// By default it is set as:
  ///
  /// ```dart
  /// Icon(
  ///   Icons.arrow_back_ios_new_rounded,
  ///   color: Colors.white,
  ///   size: 16,
  /// )
  /// ```
  final Widget? startIcon;

  /// For specifying the widget to be placed at the end
  /// of the trimmer area. You can pass `null` for hiding
  /// the widget.
  ///
  /// By default it is set as:
  ///
  /// ```dart
  /// Icon(
  ///   Icons.arrow_forward_ios_rounded,
  ///   color: Colors.white,
  ///   size: 16,
  /// )
  /// ```
  final Widget? endIcon;

  /// For specifying the size of the circular border radius
  /// to be applied to each corner of the trimmer area Container.
  ///
  /// By default it is set to `4.0`.
  final double borderRadius;

  /// Whether the thumbnail strip can be scrolled directly, by dragging
  /// anywhere outside the trim frame.
  ///
  /// When `false`, the strip can only be moved by dragging a trim handle
  /// into the edge zone and letting it auto-scroll.
  ///
  /// Only applies to the `ScrollableTrimViewer`.
  ///
  /// By default it is set to `true`.
  final bool allowManualScroll;

  /// The width, in logical pixels, of the zone at each end of the trim area
  /// that triggers auto-scrolling when a trim handle is dragged into it.
  ///
  /// The scroll speed ramps up the further the handle is pushed into the
  /// zone, so a wider zone gives finer control.
  ///
  /// Only applies to the `ScrollableTrimViewer`.
  ///
  /// By default it is set to `48.0`.
  final double autoScrollEdgeZone;

  /// The maximum auto-scroll speed, in logical pixels per second, reached
  /// when a trim handle is pushed to the very edge of the trim area.
  ///
  /// Only applies to the `ScrollableTrimViewer`.
  ///
  /// By default it is set to `600.0`.
  final double maxAutoScrollVelocity;

  /// How long a trim handle must rest inside the edge zone before
  /// auto-scrolling begins.
  ///
  /// Only applies to the `ScrollableTrimViewer`.
  ///
  /// By default it is set to `Duration.zero`, so scrolling starts as soon as
  /// the handle enters the zone.
  final Duration autoScrollStartDelay;

  /// Helps defining the Trim Area properties.
  ///
  /// A better look at the structure of the **Trim Viewer**:
  ///
  /// ![](https://raw.githubusercontent.com/sbis04/video_trimmer/new_editor/screenshots/trim_viewer_preview_small.png)
  ///
  ///
  /// All the parameters are optional:
  ///
  /// * [thumbnailFit] for specifying the image fit type of each thumbnail image.
  /// By default it is set to `BoxFit.fitHeight`.
  ///
  ///
  /// * [thumbnailQuality] for specifying the quality of each
  /// generated image thumbnail, to be displayed in the trimmer
  /// area. By default it is set to `75`.
  ///
  ///
  /// * [blurEdges] for adding a blur to the trim area edges. Use `blurColor`
  /// for specifying the color of the blur (usually it's the background color
  /// which helps in blending). By default it is set to `false`.
  ///
  ///
  /// * [blurColor] for specifying the color of the blur. Use the color of the
  /// background to blend with it. By default it is set to `Colors.black`.
  ///
  ///
  /// * [startIcon] for specifying the widget to be placed at the start
  /// of the trimmer area. You can pass `null` for hiding
  /// the widget.
  ///
  ///
  /// * [endIcon] for specifying the widget to be placed at the end
  /// of the trimmer area. You can pass `null` for hiding
  /// the widget.
  ///
  ///
  /// * [borderRadius] for specifying the size of the circular border radius
  /// to be applied to each corner of the trimmer area Container.
  /// By default it is set to `4.0`.
  ///
  ///
  /// * [allowManualScroll] for allowing the thumbnail strip to be scrolled
  /// directly, by dragging anywhere outside the trim frame. By default it is
  /// set to `true`.
  ///
  ///
  /// * [autoScrollEdgeZone] for specifying the width, in logical pixels, of
  /// the zone at each end of the trim area that triggers auto-scrolling when
  /// a trim handle is dragged into it. By default it is set to `48.0`.
  ///
  ///
  /// * [maxAutoScrollVelocity] for specifying the maximum auto-scroll speed,
  /// in logical pixels per second. By default it is set to `600.0`.
  ///
  ///
  /// * [autoScrollStartDelay] for specifying how long a trim handle must rest
  /// inside the edge zone before auto-scrolling begins. By default it is set
  /// to `Duration.zero`.
  ///
  const TrimAreaProperties({
    this.thumbnailFit = BoxFit.fitHeight,
    this.thumbnailQuality = 75,
    this.blurEdges = false,
    this.blurColor = Colors.black,
    this.startIcon,
    this.endIcon,
    this.borderRadius = 4.0,
    this.allowManualScroll = true,
    this.autoScrollEdgeZone = 48.0,
    this.maxAutoScrollVelocity = 600.0,
    this.autoScrollStartDelay = Duration.zero,
  });

  /// Helps defining the Fixed Trim Area properties.
  ///
  /// A better look at the structure of the **Trim Viewer**:
  ///
  /// ![](https://raw.githubusercontent.com/sbis04/video_trimmer/new_editor/screenshots/trim_viewer_preview_small.png)
  ///
  ///
  /// All the parameters are optional:
  ///
  /// * [thumbnailFit] for specifying the image fit type of each thumbnail image.
  /// By default it is set to `BoxFit.fitHeight`.
  ///
  ///
  /// * [thumbnailQuality] for specifying the quality of each
  /// generated image thumbnail, to be displayed in the trimmer
  /// area. By default it is set to `75`.
  ///
  ///
  /// * [borderRadius] for specifying the size of the circular border radius
  /// to be applied to each corner of the trimmer area Container.
  /// By default it is set to `4.0`.
  ///
  factory TrimAreaProperties.fixed({
    BoxFit thumbnailFit,
    int thumbnailQuality,
    double borderRadius,
  }) = FixedTrimAreaProperties;

  /// Helps defining the Trim Area properties with blur & arrows on the edges.
  ///
  /// A better look at the structure of the **Trim Viewer**:
  ///
  /// ![](https://raw.githubusercontent.com/sbis04/video_trimmer/new_editor/screenshots/trim_viewer_preview_small.png)
  ///
  factory TrimAreaProperties.edgeBlur({
    BoxFit thumbnailFit,
    int thumbnailQuality,
    bool blurEdges,
    Color blurColor,
    Widget? startIcon,
    Widget? endIcon,
    double borderRadius,
    bool allowManualScroll,
    double autoScrollEdgeZone,
    double maxAutoScrollVelocity,
    Duration autoScrollStartDelay,
  }) = _TrimAreaPropertiesWithBlur;
}

class FixedTrimAreaProperties extends TrimAreaProperties {
  /// Helps defining the Fixed Trim Area properties.
  ///
  /// A better look at the structure of the **Trim Viewer**:
  ///
  /// ![](https://raw.githubusercontent.com/sbis04/video_trimmer/new_editor/screenshots/trim_viewer_preview_small.png)
  ///
  ///
  /// All the parameters are optional:
  ///
  /// * [thumbnailFit] for specifying the image fit type of each thumbnail image.
  /// By default it is set to `BoxFit.fitHeight`.
  ///
  ///
  /// * [thumbnailQuality] for specifying the quality of each
  /// generated image thumbnail, to be displayed in the trimmer
  /// area. By default it is set to `75`.
  ///
  ///
  /// * [borderRadius] for specifying the size of the circular border radius
  /// to be applied to each corner of the trimmer area Container.
  /// By default it is set to `4.0`.
  ///
  const FixedTrimAreaProperties({
    super.thumbnailFit,
    super.thumbnailQuality,
    super.borderRadius,
  });
}

class _TrimAreaPropertiesWithBlur extends TrimAreaProperties {
  /// Blurred edges with an arrow at each end.
  ///
  /// [startIcon] and [endIcon] default to chevrons, and passing `null` for
  /// either one explicitly hides that end's icon.
  const _TrimAreaPropertiesWithBlur({
    super.thumbnailFit,
    super.thumbnailQuality,
    super.blurColor,
    super.borderRadius,
    super.allowManualScroll,
    super.autoScrollEdgeZone,
    super.maxAutoScrollVelocity,
    super.autoScrollStartDelay,
    super.blurEdges = true,
    super.startIcon = const Icon(
      Icons.arrow_back_ios_new_rounded,
      color: Colors.white,
      size: 16,
    ),
    super.endIcon = const Icon(
      Icons.arrow_forward_ios_rounded,
      color: Colors.white,
      size: 16,
    ),
  });
}
