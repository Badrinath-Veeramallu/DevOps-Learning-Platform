import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/animation_model.dart';
import '../services/step_engine.dart';

/// CustomPainter rendering directed vector edges and labels between animation actors.
///
/// Guaranteed 100% geometric parity with Web's `edgeGeometry` and SVG marker rendering.
class StageEdgesPainter extends CustomPainter {
  final Map<String, ActorModel> actors;
  final List<AnimationEdge> edges;
  final double stageWidth;
  final double stageHeight;

  const StageEdgesPainter({
    required this.actors,
    required this.edges,
    required this.stageWidth,
    required this.stageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty || actors.isEmpty) return;

    final double scaleX = size.width / StepEngine.stageWidth;
    final double scaleY = size.height / StepEngine.stageHeight;

    for (final edge in edges) {
      final a = actors[edge.from];
      final b = actors[edge.to];
      if (a == null || b == null || a.hide || b.hide) continue;

      final geom = StepEngine.edgeGeometry(a, b);
      if (geom == null) continue;

      final p1 = Offset(geom.x1 * scaleX, geom.y1 * scaleY);
      final p2 = Offset(geom.x2 * scaleX, geom.y2 * scaleY);
      final pm = Offset(geom.mx * scaleX, geom.my * scaleY);

      final Color edgeColor = switch (edge.style) {
        'ok' => AppColors.success,
        'warn' => AppColors.error,
        _ => AppColors.lightAccent,
      };

      final bool isDashed = edge.style == 'dash' || edge.style == 'warn';

      // 1. Draw connecting line
      final linePaint = Paint()
        ..color = edgeColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (isDashed) {
        _drawDashedLine(canvas, p1, p2, linePaint);
      } else {
        canvas.drawLine(p1, p2, linePaint);
      }

      // 2. Draw directional arrowhead at p2 pointing along (p2 - p1)
      _drawArrowHead(canvas, p1, p2, edgeColor);

      // 3. Draw edge label if present
      if (edge.label != null && edge.label!.isNotEmpty) {
        _drawEdgeLabel(canvas, pm, edge.label!, edgeColor);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 7.0;
    const double dashSpace = 5.0;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final double ux = dx / distance;
    final double uy = dy / distance;

    double currentDist = 0.0;
    while (currentDist < distance) {
      final double endDist = math.min(currentDist + dashWidth, distance);
      canvas.drawLine(
        Offset(p1.dx + ux * currentDist, p1.dy + uy * currentDist),
        Offset(p1.dx + ux * endDist, p1.dy + uy * endDist),
        paint,
      );
      currentDist += dashWidth + dashSpace;
    }
  }

  void _drawArrowHead(Canvas canvas, Offset p1, Offset p2, Color color) {
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double angle = math.atan2(dy, dx);
    const double arrowSize = 8.5;
    const double arrowAngle = 26.0 * (math.pi / 180.0);

    final pLeft = Offset(
      p2.dx - arrowSize * math.cos(angle - arrowAngle),
      p2.dy - arrowSize * math.sin(angle - arrowAngle),
    );
    final pRight = Offset(
      p2.dx - arrowSize * math.cos(angle + arrowAngle),
      p2.dy - arrowSize * math.sin(angle + arrowAngle),
    );

    final path = Path()
      ..moveTo(p2.dx, p2.dy)
      ..lineTo(pLeft.dx, pLeft.dy)
      ..lineTo(pRight.dx, pRight.dy)
      ..close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
  }

  void _drawEdgeLabel(Canvas canvas, Offset center, String label, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 9),
        width: textPainter.width + 10,
        height: textPainter.height + 4,
      ),
      const Radius.circular(6),
    );

    final bgPaint = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(pillRect, bgPaint);
    canvas.drawRRect(pillRect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(
        pillRect.left + 5,
        pillRect.top + 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant StageEdgesPainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.actors != actors ||
        oldDelegate.stageWidth != stageWidth ||
        oldDelegate.stageHeight != stageHeight;
  }
}

