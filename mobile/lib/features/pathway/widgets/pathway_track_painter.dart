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

/// Geometry coordinate configuration for the winding pathway roadmap.
class PathwayRoadGeometry {
  static const double laneWidth = 68.0;
  static const double xStart = 34.0;
  static const double xFinish = 34.0;

  /// Node centers for modules 1 to 7 creating a graceful side-to-side winding road.
  static const List<double> nodeX = [
    26.0, // Stop 1 (module 1) - Left
    42.0, // Stop 2 (module 2) - Right
    26.0, // Stop 3 (module 3) - Left
    42.0, // Stop 4 (module 4) - Right
    26.0, // Stop 5 (module 5) - Left
    42.0, // Stop 6 (module 6) - Right
    30.0, // Stop 7 (module 7) - Center-Left
  ];

  static double getNodeX(int moduleIndex) {
    if (moduleIndex < 0 || moduleIndex >= nodeX.length) return 34.0;
    return nodeX[moduleIndex];
  }

  static double getEntryX(int moduleIndex) {
    if (moduleIndex <= 0) {
      return (xStart + nodeX[0]) / 2.0; // 30.0
    }
    return (nodeX[moduleIndex - 1] + nodeX[moduleIndex]) / 2.0;
  }

  static double getExitX(int moduleIndex) {
    if (moduleIndex >= nodeX.length - 1) {
      return (nodeX.last + xFinish) / 2.0; // 32.0
    }
    return (nodeX[moduleIndex] + nodeX[moduleIndex + 1]) / 2.0;
  }
}

/// Painter for continuous, seamless timeline highway road segments between milestones.
class ContinuousRoadSegmentPainter extends CustomPainter {
  final bool isStart;
  final bool isFinish;
  final int moduleIndex;
  final Color cushionColor;
  final Color baseColor;
  final Color dashColor;

  ContinuousRoadSegmentPainter({
    this.isStart = false,
    this.isFinish = false,
    this.moduleIndex = 0,
    Color? cushionColor,
    Color? baseColor,
    Color? dashColor,
  })  : cushionColor = cushionColor ??
            const Color(0xFF2E171B).withValues(alpha: 0.55),
        baseColor = baseColor ?? const Color(0xFF3B1F24),
        dashColor = dashColor ?? const Color(0xFFB88A91);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    if (isStart) {
      // Connects from Start emblem center (x=42, y=26) down to exit at (35, size.height)
      const double x0 = PathwayRoadGeometry.xStart;
      final double xExit = PathwayRoadGeometry.getEntryX(0);

      path.moveTo(x0, 26);
      path.cubicTo(
        x0,
        26 + (size.height - 26) * 0.45,
        xExit,
        size.height - (size.height - 26) * 0.45,
        xExit,
        size.height,
      );
    } else if (isFinish) {
      // Connects from top (x=37, y=0) to Finish emblem center (x=42, y=26)
      final double xIn = PathwayRoadGeometry.getExitX(6);
      const double xEnd = PathwayRoadGeometry.xFinish;

      path.moveTo(xIn, 0);
      path.cubicTo(
        xIn,
        26 * 0.45,
        xEnd,
        26 * 0.55,
        xEnd,
        26,
      );
    } else {
      final double xIn = PathwayRoadGeometry.getEntryX(moduleIndex);
      final double xNode = PathwayRoadGeometry.getNodeX(moduleIndex);
      final double xOut = PathwayRoadGeometry.getExitX(moduleIndex);

      // Smooth cubic Bézier entering into node center at (xNode, 32)
      path.moveTo(xIn, 0);
      path.cubicTo(
        xIn,
        32 * 0.55,
        xNode,
        32 * 0.45,
        xNode,
        32,
      );

      // Graceful winding S-curve from node center to row exit
      final double dy = size.height - 32;
      path.cubicTo(
        xNode,
        32 + dy * 0.42,
        xOut,
        size.height - dy * 0.42,
        xOut,
        size.height,
      );
    }

    // 1. Outer Cushion
    final cushionPaint = Paint()
      ..color = cushionColor
      ..strokeWidth = 32.0
      ..style = PaintingStyle.stroke
      ..strokeCap = isStart || isFinish ? StrokeCap.round : StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, cushionPaint);

    // 2. Base Road
    final basePaint = Paint()
      ..color = baseColor
      ..strokeWidth = 20.0
      ..style = PaintingStyle.stroke
      ..strokeCap = isStart || isFinish ? StrokeCap.round : StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, basePaint);

    // 3. Dashed Center Line
    final dashPaint = Paint()
      ..color = dashColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawDashedPath(canvas, path, dashPaint, dashLength: 8.0, dashSpace: 6.0);
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
  bool shouldRepaint(covariant ContinuousRoadSegmentPainter oldDelegate) {
    return oldDelegate.isStart != isStart ||
        oldDelegate.isFinish != isFinish ||
        oldDelegate.moduleIndex != moduleIndex;
  }
}
