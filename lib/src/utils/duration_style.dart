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
  String format(DurationStyle style) {
    // DurationStyle.FORMAT_HH_MM_SS
    final formatPart = style.toString().split('.')[1].split('_');
    formatPart.removeAt(0);
    // HH_MM_SS
    final millisecondTime = inMilliseconds;
    final hoursStr = _getDisplayTimeHours(millisecondTime);
    final mStr = _getDisplayTimeMinute(millisecondTime, hours: true);
    final sStr = _getDisplayTimeSecond(millisecondTime);
    final msStr = _getDisplayTimeMillisecond(millisecondTime);
    var result = '';
    final hours = formatPart.contains('HH');
    final minute = formatPart.contains('MM');
    final second = formatPart.contains('SS');
    final milliSecond = formatPart.contains('MS');
    if (hours) {
      result += hoursStr;
    }
    if (minute) {
      if (hours) {
        result += ':';
      }
      result += mStr;
    }
    if (second) {
      if (minute) {
        result += ':';
      }
      result += sStr;
    }
    if (milliSecond) {
      if (second) {
        result += '.';
      }
      result += msStr;
    }
    return result;
  }

  /// Get display hours time.
  static String _getDisplayTimeHours(int mSec) {
    return _getRawHours(mSec).floor().toString().padLeft(2, '0');
  }

  /// Get display minute time.
  static String _getDisplayTimeMinute(int mSec, {bool hours = false}) {
    if (hours) {
      return _getMinute(mSec).floor().toString().padLeft(2, '0');
    } else {
      return _getRawMinute(mSec).floor().toString().padLeft(2, '0');
    }
  }

  /// Get display second time.
  static String _getDisplayTimeSecond(int mSec) {
    final s = (mSec % 60000 / 1000).floor();
    return s.toString().padLeft(2, '0');
  }

  /// Get display millisecond time.
  static String _getDisplayTimeMillisecond(int mSec) {
    final ms = (mSec % 1000 / 10).floor();
    return ms.toString().padLeft(2, '0');
  }

  /// Get Raw Hours.
  static int _getRawHours(int milliSecond) =>
      (milliSecond / (3600 * 1000)).floor();

  /// Get Raw Minute. 0 ~ 59. 1 hours = 0.
  static int _getMinute(int milliSecond) =>
      (milliSecond / (60 * 1000) % 60).floor();

  /// Get Raw Minute
  static int _getRawMinute(int milliSecond) => (milliSecond / 60000).floor();
}
