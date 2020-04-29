import 'package:flutter/material.dart';

class TrimEditorPainter extends CustomPainter {
  final Offset startPos;
  final Offset endPos;
  final Offset currentPos;
  final double circleSize;
  final double borderWidth;
  final double scrubberWidth;
  final bool showScrubber;
  final Color borderPaintColor;
  final Color circlePaintColor;
  final Color scrubberPaintColor;
  TrimEditorPainter({
    @required this.startPos,
    @required this.endPos,
    @required this.currentPos,
    this.circleSize = 0.5,
    this.borderWidth = 3,
    this.scrubberWidth = 1,
    this.showScrubber = true,
    this.borderPaintColor = Colors.white,
    this.circlePaintColor = Colors.white,
    this.scrubberPaintColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var borderPaint = Paint()
      ..color = borderPaintColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    var circlePaint = Paint()
      ..color = circlePaintColor
      ..strokeWidth = 1
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    var scrubberPaint = Paint()
      ..color = scrubberPaintColor
      ..strokeWidth = scrubberWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromPoints(startPos, endPos);

    if (showScrubber) {
      canvas.drawLine(
        currentPos,
        currentPos + Offset(0, endPos.dy),
        scrubberPaint,
      );
    }

    canvas.drawRect(rect, borderPaint);
    canvas.drawCircle(
        startPos + Offset(0, endPos.dy / 2), circleSize, circlePaint);
    canvas.drawCircle(
        endPos + Offset(0, -endPos.dy / 2), circleSize, circlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
