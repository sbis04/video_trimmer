import 'package:flutter_test/flutter_test.dart';
import 'package:video_trimmer/video_trimmer.dart';

void main() {
  group('DurationFormatExt.format', () {
    const oneHourThirtyMinutes = Duration(hours: 1, minutes: 30, seconds: 15);

    test('formats HH:MM:SS', () {
      expect(oneHourThirtyMinutes.format(DurationStyle.FORMAT_HH_MM_SS),
          '01:30:15');
    });

    test('formats MM:SS, carrying hours into minutes', () {
      // 1h30m is 90 minutes, so MM must not wrap back to 30.
      expect(oneHourThirtyMinutes.format(DurationStyle.FORMAT_MM_SS), '90:15');
    });

    test('formats SS', () {
      expect(const Duration(seconds: 45).format(DurationStyle.FORMAT_SS), '45');
    });

    test('formats HH:MM:SS.MS', () {
      expect(
        const Duration(hours: 2, minutes: 3, seconds: 4, milliseconds: 560)
            .format(DurationStyle.FORMAT_HH_MM_SS_MS),
        '02:03:04.56',
      );
    });

    test('formats MM:SS.MS', () {
      expect(
        const Duration(minutes: 3, seconds: 4, milliseconds: 90)
            .format(DurationStyle.FORMAT_MM_SS_MS),
        '03:04.09',
      );
    });

    test('formats SS.MS', () {
      expect(
        const Duration(seconds: 7, milliseconds: 250)
            .format(DurationStyle.FORMAT_SS_MS),
        '07.25',
      );
    });

    test('formats zero', () {
      for (final style in DurationStyle.values) {
        expect(Duration.zero.format(style), isNotEmpty,
            reason: 'style $style produced nothing for zero');
      }
      expect(Duration.zero.format(DurationStyle.FORMAT_HH_MM_SS), '00:00:00');
    });

    test('rolls over at exactly one hour', () {
      expect(const Duration(hours: 1).format(DurationStyle.FORMAT_HH_MM_SS),
          '01:00:00');
      expect(const Duration(minutes: 59, seconds: 59)
          .format(DurationStyle.FORMAT_HH_MM_SS), '00:59:59');
    });

    test('does not truncate the largest requested unit', () {
      // Regression: MM_SS used to render 1h30m15s as 30:15 and SS used to
      // render 90s as 30, silently dropping the most significant unit.
      const ninetySeconds = Duration(seconds: 90);
      expect(ninetySeconds.format(DurationStyle.FORMAT_SS), '90');
      expect(ninetySeconds.format(DurationStyle.FORMAT_MM_SS), '01:30');
      expect(
        const Duration(seconds: 90, milliseconds: 250)
            .format(DurationStyle.FORMAT_SS_MS),
        '90.25',
      );
      expect(const Duration(hours: 2, minutes: 5)
          .format(DurationStyle.FORMAT_MM_SS), '125:00');
    });

    test('handles durations beyond a day', () {
      expect(const Duration(hours: 30, minutes: 5, seconds: 1)
          .format(DurationStyle.FORMAT_HH_MM_SS), '30:05:01');
    });
  });
}
