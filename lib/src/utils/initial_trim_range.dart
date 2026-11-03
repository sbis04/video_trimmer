import 'dart:math' as math;

/// The trim range a viewer starts with, in milliseconds.
///
/// [initialStart] and [initialEnd] are what a consumer saved from
/// `onChangeStart` / `onChangeEnd` earlier (#73, #274), or just a preferred
/// default selection (#209). Either can be given alone; the other is derived
/// from the length cap. Everything is clamped to the video, and the range is
/// never longer than [maxLengthMs] (`0` or anything at least [durationMs]
/// means no cap). With neither given, this is the viewers' long-standing
/// default: from the start, as long as the cap allows.
({double start, double end}) resolveInitialTrimRange({
  required double durationMs,
  required double maxLengthMs,
  double? initialStart,
  double? initialEnd,
}) {
  if (durationMs <= 0) return (start: 0.0, end: 0.0);
  final cap =
      maxLengthMs > 0 && maxLengthMs < durationMs ? maxLengthMs : durationMs;

  var start = (initialStart ?? (initialEnd != null ? initialEnd - cap : 0.0))
      .clamp(0.0, durationMs);
  var end = (initialEnd ?? start + cap).clamp(0.0, durationMs);

  if (end <= start) {
    // Nothing selectable after start (e.g. start at the very end): keep the
    // end and reach back instead.
    end = math.max(end, start).clamp(0.0, durationMs).toDouble();
    start = math.max(0.0, end - cap);
    if (end <= start) end = math.min(durationMs, start + cap);
  }
  if (end - start > cap) {
    // Honor whichever value was given explicitly and trim the other side.
    if (initialStart == null && initialEnd != null) {
      start = end - cap;
    } else {
      end = start + cap;
    }
  }
  return (start: start.toDouble(), end: end.toDouble());
}
