import 'package:flutter_test/flutter_test.dart';
import 'package:video_trimmer/src/utils/initial_trim_range.dart';

void main() {
  ({double start, double end}) resolve({
    double? start,
    double? end,
    double duration = 30000,
    double max = 10000,
  }) =>
      resolveInitialTrimRange(
        durationMs: duration,
        maxLengthMs: max,
        initialStart: start,
        initialEnd: end,
      );

  test('defaults to the start of the clip, as long as the cap allows', () {
    expect(resolve(), (start: 0.0, end: 10000.0));
  });
  test('defaults to the whole clip without a cap', () {
    expect(resolve(max: 0), (start: 0.0, end: 30000.0));
    expect(resolve(max: 60000), (start: 0.0, end: 30000.0));
  });
  test('restores a saved range exactly', () {
    expect(resolve(start: 4000, end: 9500), (start: 4000.0, end: 9500.0));
  });
  test('start alone extends as far as the cap allows', () {
    expect(resolve(start: 12000), (start: 12000.0, end: 22000.0));
    expect(resolve(start: 26000), (start: 26000.0, end: 30000.0));
  });
  test('end alone reaches back by the cap', () {
    expect(resolve(end: 25000), (start: 15000.0, end: 25000.0));
    expect(resolve(end: 4000), (start: 0.0, end: 4000.0));
  });
  test('a shorter default selection (#209)', () {
    expect(resolve(end: 3000, max: 30000), (start: 0.0, end: 3000.0));
  });
  test('a saved range longer than the cap keeps its start', () {
    expect(resolve(start: 2000, end: 20000), (start: 2000.0, end: 12000.0));
  });
  test('values outside the clip are clamped', () {
    expect(resolve(start: -500, end: 45000), (start: 0.0, end: 10000.0));
  });
  test('a start at the very end still yields a selectable range', () {
    expect(resolve(start: 30000), (start: 20000.0, end: 30000.0));
  });
  test('an inverted range collapses to a valid one', () {
    final r = resolve(start: 9000, end: 3000);
    expect(r.end, greaterThan(r.start));
    expect(r.end - r.start, lessThanOrEqualTo(10000));
  });
}
