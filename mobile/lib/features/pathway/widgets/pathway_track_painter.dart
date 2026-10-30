import 'package:flutter/material.dart';

/// Custom painter that draws the winding / S-curved learning pathway road.
///
/// Features 3 distinct layered passes matching the Web application:
/// 1. Subtle Road Cushion (outer glow / roadbed buffer)
/// 2. Road Track Base (solid burgundy surface)
/// 3. Dashed Center Line (dusty rose dashed markings)
class PathwayTrackPainter extends CustomPainter {
  final List<Offset> points;
  final Color cushionColor;
  final Color baseColor;
  final Color dashColor;

  PathwayTrackPainter({
    required this.points,
    Color? cushionColor,
    Color? baseColor,
    Color? dashColor,
  })  : cushionColor = cushionColor ??
            const Color(0xFF2E171B).withValues(alpha: 0.55),
        baseColor = baseColor ?? const Color(0xFF3B1F24),
        dashColor = dashColor ?? const Color(0xFFB88A91);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Construct the continuous smooth pathway
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      // Vertical S-curve connection between two milestones
      final midY = (p1.dy + p2.dy) / 2;
      path.cubicTo(
        p1.dx,
        midY,
        p2.dx,
        midY,
        p2.dx,
        p2.dy,
      );
    }

    // 1. Outer Cushion
    final cushionPaint = Paint()
      ..color = cushionColor
      ..strokeWidth = 32.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, cushionPaint);

    // 2. Base Road
    final basePaint = Paint()
      ..color = baseColor
      ..strokeWidth = 20.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, basePaint);

    // 3. Dashed Center Line
    final dashPaint = Paint()
      ..color = dashColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawDashedPath(canvas, path, dashPaint, dashLength: 10.0, dashSpace: 8.0);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path source,
    Paint paint, {
    required double dashLength,
    required double dashSpace,
  }) {
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashLength + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant PathwayTrackPainter oldDelegate) {
    if (oldDelegate.points.length != points.length) return true;
    for (int i = 0; i < points.length; i++) {
      if (oldDelegate.points[i] != points[i]) return true;
    }
    return oldDelegate.cushionColor != cushionColor ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.dashColor != dashColor;
  }
}
