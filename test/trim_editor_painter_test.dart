import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_trimmer/src/trim_viewer/trim_editor_painter.dart';
import 'package:video_trimmer/video_trimmer.dart';

void main() {
  group('TrimHandleHeight', () {
    test('pixels is used as is', () {
      expect(const TrimHandleHeight.pixels(24).resolve(60), 24);
    });

    test('percent is relative to the trim area', () {
      expect(const TrimHandleHeight.percent(50).resolve(60), 30);
      expect(const TrimHandleHeight.percent(100).resolve(60), 60);
      expect(const TrimHandleHeight.percent(0).resolve(60), 0);
    });

    test('never exceeds the trim area', () {
      expect(const TrimHandleHeight.pixels(200).resolve(60), 60);
    });

    test('has value equality', () {
      expect(
          const TrimHandleHeight.pixels(20), const TrimHandleHeight.pixels(20));
      expect(const TrimHandleHeight.pixels(20),
          isNot(const TrimHandleHeight.percent(20)));
    });
  });

  group('TrimEditorProperties', () {
    test('defaults to line handles at half the trim area height', () {
      const props = TrimEditorProperties();
      expect(props.handleStyle, TrimHandleStyle.line);
      expect(props.handleHeight, const TrimHandleHeight.percent(50));
    });
  });

  group('TrimEditorPainter handles', () {
    const size = Size(300, 60);

    TrimEditorPainter painter({
      TrimHandleStyle style = TrimHandleStyle.line,
      TrimHandleHeight height = const TrimHandleHeight.percent(50),
    }) =>
        TrimEditorPainter(
          startPos: const Offset(40, 0),
          endPos: const Offset(240, 60),
          scrubberAnimationDx: 40,
          startCircleSize: 5,
          endCircleSize: 8,
          handleStyle: style,
          handleHeight: height,
        );

    test('line handles are bars centered on each edge', () {
      expect(
        (Canvas canvas) => painter().paint(canvas, size),
        paints
          ..rrect() // the trim frame
          ..rrect(
            rrect: RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: const Offset(40, 30), width: 5, height: 30),
              const Radius.circular(2.5),
            ),
          )
          ..rrect(
            rrect: RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: const Offset(240, 30), width: 8, height: 30),
              const Radius.circular(4),
            ),
          ),
      );
      expect((Canvas canvas) => painter().paint(canvas, size),
          isNot(paints..circle()));
    });

    test('line handle height can be set in pixels', () {
      expect(
        (Canvas canvas) => painter(height: const TrimHandleHeight.pixels(44))
            .paint(canvas, size),
        paints
          ..rrect()
          ..rrect(
            rrect: RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: const Offset(40, 30), width: 5, height: 44),
              const Radius.circular(2.5),
            ),
          ),
      );
    });

    test('circle handles keep the pre-6.0.0 look', () {
      expect(
        (Canvas canvas) =>
            painter(style: TrimHandleStyle.circle).paint(canvas, size),
        paints
          ..rrect()
          ..circle(x: 40, y: 30, radius: 5)
          ..circle(x: 240, y: 30, radius: 8),
      );
    });
  });
}
