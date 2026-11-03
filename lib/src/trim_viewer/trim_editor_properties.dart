import 'package:flutter/material.dart';

/// The shape of the drag handles at the two ends of the trim area.
enum TrimHandleStyle {
  /// A rounded vertical bar centered on each edge of the trim area, as tall as
  /// [TrimEditorProperties.handleHeight]. This is the default.
  line,

  /// A dot centered on each edge of the trim area, the style used before 6.0.0.
  circle,
}

/// The height of a [TrimHandleStyle.line] handle, either in logical pixels or
/// as a percentage of the trim area's height.
///
/// The resolved height never exceeds the trim area's height.
@immutable
class TrimHandleHeight {
  /// A fixed height in logical pixels.
  const TrimHandleHeight.pixels(double this.pixels)
      : percent = null,
        assert(pixels >= 0);

  /// A height relative to the trim area: `50` is half of it, `100` all of it.
  const TrimHandleHeight.percent(double this.percent)
      : pixels = null,
        assert(percent >= 0 && percent <= 100);

  /// The height in logical pixels, when created with [TrimHandleHeight.pixels].
  final double? pixels;

  /// The height as a percentage of the trim area, when created with
  /// [TrimHandleHeight.percent].
  final double? percent;

  /// The handle height for a trim area that is [areaHeight] tall.
  double resolve(double areaHeight) {
    final height = pixels ?? areaHeight * percent! / 100;
    return height.clamp(0.0, areaHeight).toDouble();
  }

  @override
  bool operator ==(Object other) =>
      other is TrimHandleHeight &&
      other.pixels == pixels &&
      other.percent == percent;

  @override
  int get hashCode => Object.hash(pixels, percent);

  @override
  String toString() => pixels != null
      ? 'TrimHandleHeight.pixels($pixels)'
      : 'TrimHandleHeight.percent($percent)';
}

class TrimEditorProperties {
  /// The shape of the two drag handles. By default it is set to
  /// [TrimHandleStyle.line].
  final TrimHandleStyle handleStyle;

  /// The height of a [TrimHandleStyle.line] handle, in pixels or as a
  /// percentage of the trim area's height. Ignored for
  /// [TrimHandleStyle.circle].
  ///
  /// By default it is set to `TrimHandleHeight.percent(50)`.
  final TrimHandleHeight handleHeight;

  /// For specifying a size to the holder at the
  /// two ends of the video trimmer area, while it is `idle`: the radius of a
  /// [TrimHandleStyle.circle] handle, or the width of a [TrimHandleStyle.line]
  /// handle.
  ///
  /// By default it is set to `5.0`.
  final double circleSize;

  /// For specifying a size to the holder at
  /// the two ends of the video trimmer area, while it is being
  /// `dragged`: the radius of a [TrimHandleStyle.circle] handle, or the width
  /// of a [TrimHandleStyle.line] handle.
  ///
  /// By default it is set to `8.0`.
  final double circleSizeOnDrag;

  /// For specifying the width of the border around
  /// the trim area. By default it is set to `3`.
  final double borderWidth;

  /// For specifying the width of the video scrubber
  final double scrubberWidth;

  /// For specifying a circular border radius
  /// to the corners of the trim area.
  ///
  /// By default it is set to `4.0`.
  final double borderRadius;

  /// For specifying a color to the drag handles.
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

  /// Determines the touch size of the side handles, left and right. The rest, in
  /// the center, will move the whole frame if [maxVideoLength] is inferior to the
  /// total duration of the video.
  final int sideTapSize;

  /// Helps defining the Trim Editor properties.
  ///
  /// A better look at the structure of the **Trim Viewer**:
  ///
  /// ![](https://raw.githubusercontent.com/sbis04/video_trimmer/refs/heads/main/screenshots/trim_viewer_anatomy.png)
  ///
  ///
  /// All the parameters are optional:
  ///
  /// * [handleStyle] for the shape of the drag handles, a line or a circle.
  /// By default it is set to [TrimHandleStyle.line].
  ///
  ///
  /// * [handleHeight] for the height of a line handle, in pixels or as a
  /// percentage of the trim area. By default it is set to
  /// `TrimHandleHeight.percent(50)`.
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
  /// * [borderWidth] for specifying the width of the border around
  /// the trim area. By default it is set to `3.0`.
  ///
  /// * [scrubberWidth] for specifying the width of the video scrubber.
  /// By default it is set to `1.0`.
  ///
  ///
  /// * [borderRadius] for applying a circular border radius
  /// to the corners of the trim area. By default it is set to `4.0`.
  ///
  ///
  /// * [circlePaintColor] for specifying a color to the drag handles.
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
  /// * [sideTapSize] determines the touch size of the side handles, left and right.
  /// The rest, in the center, will move the whole frame if [maxVideoLength] is
  /// inferior to the total duration of the video.
  ///
  const TrimEditorProperties({
    this.handleStyle = TrimHandleStyle.line,
    this.handleHeight = const TrimHandleHeight.percent(50),
    this.circleSize = 5.0,
    this.circleSizeOnDrag = 8.0,
    this.borderWidth = 3.0,
    this.scrubberWidth = 1.0,
    this.borderRadius = 4.0,
    this.circlePaintColor = Colors.white,
    this.borderPaintColor = Colors.white,
    this.scrubberPaintColor = Colors.white,
    this.sideTapSize = 24,
  });
}
