import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/animation_model.dart';
import 'actor_widget.dart';
import 'stage_edges_painter.dart';

/// Interactive rendering canvas for a Git animation frame.
///
/// Features:
/// - Coordinate mapping from the 1000x400 normalized vector space
/// - Background grid backdrop matching Web's `.sa-stage`
/// - Z-indexed layers: Zones -> Directional Edges -> Foreground Actors
/// - Responsive horizontal pan/scroll on compact mobile widths
class StageCanvas extends StatelessWidget {
  final AnimationFrame frame;

  const StageCanvas({
    super.key,
    required this.frame,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Guarantee at least 540 dp of stage width for readable labels on small screens
        final double stageWidth = math.max(constraints.maxWidth, 540.0);
        final double stageHeight = stageWidth / 2.5; // Aspect ratio 1000:400

        // Separate zones (background layer) and foreground actors
        final zoneActors = <ActorModel>[];
        final fgActors = <ActorModel>[];

        frame.actors.forEach((_, actor) {
          if (actor.k == 'zone') {
            zoneActors.add(actor);
          } else {
            fgActors.add(actor);
          }
        });

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Container(
            width: stageWidth,
            height: stageHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF0D121F),
              border: Border.all(color: AppColors.borderDefault, width: 1),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Subtle Engineering Grid Pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridBackgroundPainter(),
                  ),
                ),

                // 2. Background Zones Layer
                ...zoneActors.map(
                  (a) => ActorWidget(
                    key: ValueKey('zone-${a.id}'),
                    actor: a,
                    stageWidth: stageWidth,
                    stageHeight: stageHeight,
                  ),
                ),

                // 3. Directional Edges & Arrows Layer
                Positioned.fill(
                  child: CustomPaint(
                    painter: StageEdgesPainter(
                      actors: frame.actors,
                      edges: frame.edges,
                      stageWidth: stageWidth,
                      stageHeight: stageHeight,
                    ),
                  ),
                ),

                // 4. Foreground Interactive Actors (Commits, Files, Boxes, Code, Pills)
                ...fgActors.map(
                  (a) => ActorWidget(
                    key: ValueKey('actor-${a.id}'),
                    actor: a,
                    stageWidth: stageWidth,
                    stageHeight: stageHeight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.8;

    const double step = 28.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

