import 'package:flutter_test/flutter_test.dart';
import 'package:video_trimmer/src/utils/output_naming.dart';

void main() {
  final timestamp = DateTime(2023, 4, 28, 9, 45, 54);

  group('sanitizeFileName', () {
    test('strips the characters that broke downstream media tooling', () {
      // Issue #203: colons and commas from the old localized timestamp made
      // MediaMetadataRetriever reject the path outright.
      expect(sanitizeFileName('clip_trimmed:Apr28,2023-09:45:54'),
          'clip_trimmed_Apr28_2023-09_45_54');
    });

    test('replaces spaces and path separators', () {
      expect(sanitizeFileName('my holiday clip'), 'my_holiday_clip');
      expect(sanitizeFileName('a/b\\c'), 'a_b_c');
    });

    test('collapses runs of underscores', () {
      expect(sanitizeFileName('a   b'), 'a_b');
    });

    test('trims leading and trailing separators', () {
      expect(sanitizeFileName('  spaced  '), 'spaced');
      expect(sanitizeFileName('...dots...'), 'dots');
    });

    test('keeps dots, dashes and underscores inside the name', () {
      expect(sanitizeFileName('v1.2_final-cut'), 'v1.2_final-cut');
    });

    test('falls back to untitled when nothing usable is left', () {
      expect(sanitizeFileName('///'), 'untitled');
      expect(sanitizeFileName(''), 'untitled');
    });

    test('handles non-ASCII by replacing it', () {
      expect(sanitizeFileName('vidéo'), 'vid_o');
    });
  });

  group('buildOutputFileName', () {
    test('uses a filesystem-safe timestamp', () {
      expect(
        buildOutputFileName(sourcePath: '/videos/clip.mp4', timestamp: timestamp),
        'clip_trimmed_20230428_094554',
      );
    });

    test('produces a name free of characters that need escaping', () {
      final name = buildOutputFileName(
          sourcePath: '/videos/clip.mp4', timestamp: timestamp);
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains(',')));
      expect(name, isNot(contains(' ')));
    });

    test('keeps the whole base name when it contains dots', () {
      // The old split('.')[0] truncated this to `my`.
      expect(
        buildOutputFileName(
            sourcePath: '/videos/my.holiday.clip.mp4', timestamp: timestamp),
        'my.holiday.clip_trimmed_20230428_094554',
      );
    });

    test('sanitizes a source name with spaces', () {
      expect(
        buildOutputFileName(
            sourcePath: '/videos/beach day.mov', timestamp: timestamp),
        'beach_day_trimmed_20230428_094554',
      );
    });

    test('prefers a custom name, sanitized', () {
      expect(
        buildOutputFileName(
          sourcePath: '/videos/clip.mp4',
          timestamp: timestamp,
          customName: 'My Output:1',
        ),
        'My_Output_1',
      );
    });

    test('ignores a blank custom name', () {
      expect(
        buildOutputFileName(
          sourcePath: '/videos/clip.mp4',
          timestamp: timestamp,
          customName: '   ',
        ),
        'clip_trimmed_20230428_094554',
      );
    });

    test('is stable for the same inputs', () {
      final a = buildOutputFileName(
          sourcePath: '/videos/clip.mp4', timestamp: timestamp);
      final b = buildOutputFileName(
          sourcePath: '/videos/clip.mp4', timestamp: timestamp);
      expect(a, b);
    });
  });
}
