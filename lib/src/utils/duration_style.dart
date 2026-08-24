// ignore_for_file: constant_identifier_names

enum DurationStyle {
  FORMAT_HH_MM_SS,
  FORMAT_MM_SS,
  FORMAT_SS,
  FORMAT_HH_MM_SS_MS,
  FORMAT_MM_SS_MS,
  FORMAT_SS_MS,
}

extension DurationFormatExt on Duration {
  /// Renders this duration in the given [style].
  ///
  /// The largest unit the style asks for is never truncated: `FORMAT_MM_SS`
  /// shows 1h30m15s as `90:15`, not `30:15`. Smaller units wrap as usual.
  String format(DurationStyle style) {
    // e.g. FORMAT_HH_MM_SS -> {HH, MM, SS}
    final parts = style.name.split('_').skip(1).toSet();
    final hours = parts.contains('HH');
    final minutes = parts.contains('MM');
    final seconds = parts.contains('SS');
    final milliSeconds = parts.contains('MS');

    final ms = inMilliseconds;
    final buffer = StringBuffer();

    if (hours) {
      buffer.write(_pad(_rawHours(ms)));
    }
    if (minutes) {
      if (hours) buffer.write(':');
      // Raw minutes when no hours field is carrying the overflow.
      buffer.write(_pad(hours ? _minuteOfHour(ms) : _rawMinutes(ms)));
    }
    if (seconds) {
      if (minutes) buffer.write(':');
      // Likewise: raw seconds when neither hours nor minutes are shown.
      buffer.write(
          _pad(hours || minutes ? _secondOfMinute(ms) : _rawSeconds(ms)));
    }
    if (milliSeconds) {
      if (seconds) buffer.write('.');
      buffer.write(_pad(_centisecondOfSecond(ms)));
    }
    return buffer.toString();
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');

  /// Total whole hours.
  static int _rawHours(int ms) => ms ~/ Duration.millisecondsPerHour;

  /// Total whole minutes, ignoring any hours field.
  static int _rawMinutes(int ms) => ms ~/ Duration.millisecondsPerMinute;

  /// Minutes within the hour, 0-59.
  static int _minuteOfHour(int ms) =>
      (ms ~/ Duration.millisecondsPerMinute) % 60;

  /// Total whole seconds, ignoring any hours or minutes field.
  static int _rawSeconds(int ms) => ms ~/ Duration.millisecondsPerSecond;

  /// Seconds within the minute, 0-59.
  static int _secondOfMinute(int ms) =>
      (ms ~/ Duration.millisecondsPerSecond) % 60;

  /// Hundredths of a second within the second, 0-99.
  static int _centisecondOfSecond(int ms) => (ms % 1000) ~/ 10;
}
