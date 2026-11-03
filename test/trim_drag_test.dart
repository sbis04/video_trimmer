import 'package:flutter_test/flutter_test.dart';
import 'package:video_trimmer/src/utils/editor_drag_type.dart';
import 'package:video_trimmer/src/utils/trim_drag.dart';

void main() {
  ({double start, double end}) drag(EditorDragType type, double dx,
          {double start = 100,
          double end = 300,
          double max = 250,
          double min = 0}) =>
      clampTrimDrag(
        type: type,
        start: start,
        end: end,
        dx: dx,
        viewerWidth: 400,
        maxLength: max,
        minLength: min,
      );

  group('center', () {
    test('moves both edges by dx', () {
      expect(drag(EditorDragType.center, 20), (start: 120.0, end: 320.0));
    });
    test('stops exactly on the right edge instead of short of it', () {
      // 300 + 120 would overshoot 400; the old check rejected the whole move
      // and left the frame 100 px short.
      expect(drag(EditorDragType.center, 120), (start: 200.0, end: 400.0));
    });
    test('stops exactly on the left edge', () {
      expect(drag(EditorDragType.center, -150), (start: 0.0, end: 200.0));
    });
  });

  group('right handle', () {
    test('clamps to the viewer width', () {
      expect(drag(EditorDragType.right, 500, start: 200),
          (start: 200.0, end: 400.0));
    });
    test('clamps to maxLength', () {
      expect(drag(EditorDragType.right, 500), (start: 100.0, end: 350.0));
    });
    test('cannot cross the left handle', () {
      expect(drag(EditorDragType.right, -500), (start: 100.0, end: 100.0));
    });
  });

  group('left handle', () {
    test('clamps to zero', () {
      expect(
          drag(EditorDragType.left, -500, end: 200), (start: 0.0, end: 200.0));
    });
    test('clamps to maxLength', () {
      expect(drag(EditorDragType.left, -500), (start: 50.0, end: 300.0));
    });
    test('cannot cross the right handle', () {
      expect(drag(EditorDragType.left, 500), (start: 300.0, end: 300.0));
    });
  });

  group('minLength', () {
    test('the right handle stops at start + minLength', () {
      expect(drag(EditorDragType.right, -500, min: 80),
          (start: 100.0, end: 180.0));
    });
    test('the left handle stops at end - minLength', () {
      expect(
          drag(EditorDragType.left, 500, min: 80), (start: 220.0, end: 300.0));
    });
    test('min == max pins both handles; only the frame moves', () {
      expect(drag(EditorDragType.left, -30, min: 200, max: 200),
          (start: 100.0, end: 300.0));
      expect(drag(EditorDragType.right, 30, min: 200, max: 200),
          (start: 100.0, end: 300.0));
      expect(drag(EditorDragType.center, 30, min: 200, max: 200),
          (start: 130.0, end: 330.0));
    });
    test('a minLength above maxLength is treated as maxLength', () {
      expect(drag(EditorDragType.right, -500, min: 999),
          (start: 100.0, end: 350.0));
    });
  });
}
