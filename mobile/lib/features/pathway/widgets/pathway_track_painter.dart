import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Paints a continuous, smooth winding cubic-Bézier road across a list of
/// milestone anchor points ([points]) in the background of the roadmap.
///
/// Purely visual and completely independent from learning module data.
class PathwayTrackPainter extends CustomPainter {
  final List<Offset> points;
  final Color cushionColor;
  final Color baseColor;
  final Color dashColor;
  final double cushionWidth;
  final double roadWidth;
  final double dashWidth;
  final double dashLength;
  final double dashSpace;
  final double curveTension;

  PathwayTrackPainter({
    required this.points,
    Color? cushionColor,
    Color? baseColor,
    Color? dashColor,
    this.cushionWidth = 36.0,
    this.roadWidth = 24.0,
    this.dashWidth = 2.8,
    this.dashLength = 10.0,
    this.dashSpace = 10.0,
    this.curveTension = 0.54,
  })  : cushionColor = cushionColor ?? AppColors.roadCushion,
        baseColor = baseColor ?? AppColors.paleBlush,
        dashColor = dashColor ?? AppColors.roadDash;

  /// Builds a C1-smooth continuous cubic-Bézier [Path] visiting every anchor.
  Path buildRoadPath() {
    final path = Path();
    if (points.length < 2) return path;

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final dy = p2.dy - p1.dy;

      // Vertical departure & arrival tangents ensure smooth S-curves without kinks.
      final c1 = Offset(p1.dx, p1.dy + dy * curveTension);
      final c2 = Offset(p2.dx, p2.dy - dy * curveTension);

      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final path = buildRoadPath();

    // 1. Soft pale blush outer cushion (halo around the road bed)
    final cushionPaint = Paint()
      ..color = cushionColor
      ..strokeWidth = cushionWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, cushionPaint);

    // 2. Pale pink/blush continuous road surface
    final basePaint = Paint()
      ..color = baseColor
      ..strokeWidth = roadWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, basePaint);

    // 3. Muted burgundy dashed centerline
    final dashPaint = Paint()
      ..color = dashColor
      ..strokeWidth = dashWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawDashedPath(
      canvas,
      path,
      dashPaint,
      dashLength: dashLength,
      dashSpace: dashSpace,
    );
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
        oldDelegate.dashColor != dashColor ||
        oldDelegate.cushionWidth != cushionWidth ||
        oldDelegate.roadWidth != roadWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.curveTension != curveTension;
  }
}

/// Geometry coordinate helper retained for standalone per-row stop previews.
class PathwayRoadGeometry {
  static const double laneWidth = 68.0;
  static const double xStart = 34.0;
  static const double xFinish = 34.0;

  static const List<double> nodeX = [
    26.0,
    42.0,
    26.0,
    42.0,
    26.0,
    42.0,
    30.0,
  ];

  static double getNodeX(int moduleIndex) {
    if (moduleIndex < 0 || moduleIndex >= nodeX.length) return 34.0;
    return nodeX[moduleIndex];
  }

  static double getEntryX(int moduleIndex) {
    if (moduleIndex <= 0) {
      return (xStart + nodeX[0]) / 2.0;
    }
    return (nodeX[moduleIndex - 1] + nodeX[moduleIndex]) / 2.0;
  }

  static double getExitX(int moduleIndex) {
    if (moduleIndex >= nodeX.length - 1) {
      return (nodeX.last + xFinish) / 2.0;
    }
    return (nodeX[moduleIndex] + nodeX[moduleIndex + 1]) / 2.0;
  }
}

/// Segment painter retained for standalone [PathwayStopNode] rendering when
/// `showContinuousRoad` is enabled outside [GitPathwayMap].
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
  })  : cushionColor = cushionColor ?? AppColors.roadCushion,
        baseColor = baseColor ?? AppColors.paleBlush,
        dashColor = dashColor ?? AppColors.roadDash;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    if (isStart) {
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

      path.moveTo(xIn, 0);
      path.cubicTo(
        xIn,
        32 * 0.55,
        xNode,
        32 * 0.45,
        xNode,
        32,
      );

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

    final cushionPaint = Paint()
      ..color = cushionColor
      ..strokeWidth = 32.0
      ..style = PaintingStyle.stroke
      ..strokeCap = isStart || isFinish ? StrokeCap.round : StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, cushionPaint);

    final basePaint = Paint()
      ..color = baseColor
      ..strokeWidth = 20.0
      ..style = PaintingStyle.stroke
      ..strokeCap = isStart || isFinish ? StrokeCap.round : StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, basePaint);

    final dashPaint = Paint()
      ..color = dashColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      const double dashLength = 8.0;
      const double dashSpace = 8.0;
      while (distance < metric.length) {
        final length = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, dashPaint);
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
