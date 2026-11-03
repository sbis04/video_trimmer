import 'dart:math' as math;

import 'package:video_trimmer/src/utils/editor_drag_type.dart';

/// Moves the trim frame's edges by a horizontal drag of [dx], clamped so the
/// frame stays inside `[0, viewerWidth]` and is never longer than [maxLength]
/// or shorter than [minLength] pixels.
///
/// A drag that would cross a bound stops exactly on it. The viewers used to
/// reject such a drag outright, so a fast drag stopped up to one pointer delta
/// short of the edge and the clip's last frames could not be selected.
({double start, double end}) clampTrimDrag({
  required EditorDragType type,
  required double start,
  required double end,
  required double dx,
  required double viewerWidth,
  required double maxLength,
  double minLength = 0,
}) {
  final min = minLength.clamp(0.0, maxLength);
  switch (type) {
    case EditorDragType.left:
      final lowest = math.max(0.0, end - maxLength);
      final highest = math.max(lowest, end - min);
      return (start: (start + dx).clamp(lowest, highest), end: end);
    case EditorDragType.right:
      final highest = math.min(viewerWidth, start + maxLength);
      final lowest = math.min(highest, start + min);
      return (start: start, end: (end + dx).clamp(lowest, highest));
    case EditorDragType.center:
      final shift = dx.clamp(-start, math.max(0.0, viewerWidth - end));
      return (start: start + shift, end: end + shift);
  }
}
