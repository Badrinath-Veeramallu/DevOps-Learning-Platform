import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/curriculum_model.dart';
import 'milestone_monument.dart';
import 'pathway_stop_node.dart';

/// Geometry coordinate configuration for the 6-stop Linux pathway roadmap.
class LinuxRoadGeometry {
  static const double laneWidth = 68.0;
  static const double xStart = 34.0;
  static const double xFinish = 42.0; // Right side aligned with Stop 6

  static const List<double> nodeX = [
    26.0, // Stop 1 (module 1) - Left
    42.0, // Stop 2 (module 2) - Right
    26.0, // Stop 3 (module 3) - Left
    42.0, // Stop 4 (module 4) - Right
    26.0, // Stop 5 (module 5) - Left
    42.0, // Stop 6 (module 6) - Right
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
      return (nodeX.last + xFinish) / 2.0; // 42.0
    }
    return (nodeX[moduleIndex] + nodeX[moduleIndex + 1]) / 2.0;
  }
}

/// CustomPainter rendering smooth S-curved highway road segments for Linux.
class LinuxContinuousRoadPainter extends CustomPainter {
  final bool isStart;
  final bool isFinish;
  final int moduleIndex;
  final Color cushionColor;
  final Color baseColor;
  final Color dashColor;

  LinuxContinuousRoadPainter({
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
      const double x0 = LinuxRoadGeometry.xStart;
      final double xExit = LinuxRoadGeometry.getEntryX(0);

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
      const double xIn = LinuxRoadGeometry.xFinish;
      const double xEnd = LinuxRoadGeometry.xFinish;

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
      final double xIn = LinuxRoadGeometry.getEntryX(moduleIndex);
      final double xNode = LinuxRoadGeometry.getNodeX(moduleIndex);
      final double xOut = LinuxRoadGeometry.getExitX(moduleIndex);

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

    // 1. Cushion Outer Glow
    final cushionPaint = Paint()
      ..color = cushionColor
      ..strokeWidth = 32.0
      ..style = PaintingStyle.stroke
      ..strokeCap = isStart || isFinish ? StrokeCap.round : StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, cushionPaint);

    // 2. Base Surface
    final basePaint = Paint()
      ..color = baseColor
      ..strokeWidth = 20.0
      ..style = PaintingStyle.stroke
      ..strokeCap = isStart || isFinish ? StrokeCap.round : StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, basePaint);

    // 3. Dashed Center Markings
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
  bool shouldRepaint(covariant LinuxContinuousRoadPainter oldDelegate) {
    return oldDelegate.isStart != isStart ||
        oldDelegate.isFinish != isFinish ||
        oldDelegate.moduleIndex != moduleIndex;
  }
}

/// Interactive 6-stop Linux Essentials learning pathway map.
///
/// Features:
/// - Exact Web curriculum order (6 stops)
/// - Connected winding pathway track with layered road cushions & dashed markings
/// - START and FINISH milestone monuments
/// - Responsive adaptation (linear mobile highway on phones, winding alternating S-curves on tablets/wide screens)
/// - Visual state indication: Completed, Current Focus, Upcoming
/// - Direct navigation to `/pathways/linux/:moduleId`
class LinuxPathwayMap extends StatelessWidget {
  final List<CurriculumModule> modules;
  final Set<String> completedModuleIds;
  final ValueChanged<String> onSelectModule;
  final String finishText;

  const LinuxPathwayMap({
    super.key,
    required this.modules,
    required this.completedModuleIds,
    required this.onSelectModule,
    this.finishText = 'Linux System Administration Mastered!',
  });

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.lightAccent),
        ),
      );
    }

    final currentStopIndex = modules.indexWhere(
      (m) => !completedModuleIds.contains(m.id),
    );
    final activeIndex =
        currentStopIndex == -1 ? modules.length - 1 : currentStopIndex;
    final isAllCompleted =
        modules.isNotEmpty && completedModuleIds.length >= modules.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return _buildTabletWindingLayout(
            context,
            constraints.maxWidth,
            activeIndex,
            isAllCompleted,
          );
        } else {
          return _buildMobileLayout(
            context,
            constraints.maxWidth,
            activeIndex,
            isAllCompleted,
          );
        }
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    double width,
    int activeIndex,
    bool isAllCompleted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // START Monument Row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: LinuxRoadGeometry.laneWidth,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: LinuxContinuousRoadPainter(isStart: true),
                      ),
                    ),
                    Positioned(
                      left: LinuxRoadGeometry.xStart - 26,
                      top: 0,
                      child: const MilestoneMonument(
                        type: MilestoneMonumentType.start,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 14, bottom: 20),
                  child: Text(
                    'Journey Kickoff',
                    style: TextStyle(
                      color: AppColors.textSubtle,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 6 Stops with built-in continuous smooth winding road
        ...List.generate(modules.length, (idx) {
          final module = modules[idx];
          final isCompleted = completedModuleIds.contains(module.id);
          final isCurrent = idx == activeIndex && !isCompleted;
          final status = isCompleted
              ? StopStatus.completed
              : (isCurrent ? StopStatus.current : StopStatus.upcoming);

          final stopNode = PathwayStopNode(
            module: module,
            status: status,
            onSelectModule: onSelectModule,
            totalStops: modules.length,
            showContinuousRoad: false,
          );

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: LinuxRoadGeometry.laneWidth,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: LinuxContinuousRoadPainter(
                            moduleIndex: idx,
                          ),
                        ),
                      ),
                      Positioned(
                        left: LinuxRoadGeometry.getNodeX(idx) - 24,
                        top: 8,
                        child: stopNode.buildNodeCircle(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: stopNode.buildStopCard(context),
                  ),
                ),
              ],
            ),
          );
        }),

        // FINISH Monument Row (aligned with Stop 6 on the right)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: LinuxRoadGeometry.laneWidth,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: LinuxContinuousRoadPainter(isFinish: true),
                      ),
                    ),
                    Positioned(
                      left: LinuxRoadGeometry.xFinish - 26,
                      top: 0,
                      child: MilestoneMonument(
                        type: MilestoneMonumentType.finish,
                        isAllCompleted: isAllCompleted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    isAllCompleted
                        ? finishText
                        : 'Linux Pathway Milestone Finish',
                    style: TextStyle(
                      color: isAllCompleted
                          ? AppColors.success
                          : AppColors.textSubtle,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletWindingLayout(
    BuildContext context,
    double width,
    int activeIndex,
    bool isAllCompleted,
  ) {
    return Column(
      children: [
        // START Monument
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MilestoneMonument(type: MilestoneMonumentType.start),
                const SizedBox(width: 14),
                const Text(
                  'Journey Kickoff',
                  style: TextStyle(
                    color: AppColors.textSubtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Alternating 6 Stops
        ...List.generate(modules.length, (idx) {
          final module = modules[idx];
          final isCompleted = completedModuleIds.contains(module.id);
          final isCurrent = idx == activeIndex && !isCompleted;
          final status = isCompleted
              ? StopStatus.completed
              : (isCurrent ? StopStatus.current : StopStatus.upcoming);
          final isLeft = idx % 2 == 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              mainAxisAlignment:
                  isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: isLeft
                  ? [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 30),
                        child: PathwayStopNode(
                          module: module,
                          status: status,
                          onSelectModule: onSelectModule,
                          isNodeOnly: true,
                          totalStops: modules.length,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: PathwayStopNode(
                          module: module,
                          status: status,
                          onSelectModule: onSelectModule,
                          totalStops: modules.length,
                        ).buildStopCard(context),
                      ),
                      const SizedBox(width: 60),
                    ]
                  : [
                      const SizedBox(width: 60),
                      Expanded(
                        child: PathwayStopNode(
                          module: module,
                          status: status,
                          onSelectModule: onSelectModule,
                          totalStops: modules.length,
                        ).buildStopCard(context),
                      ),
                      const SizedBox(width: 24),
                      Padding(
                        padding: const EdgeInsets.only(top: 8, right: 30),
                        child: PathwayStopNode(
                          module: module,
                          status: status,
                          onSelectModule: onSelectModule,
                          isNodeOnly: true,
                          totalStops: modules.length,
                        ),
                      ),
                    ],
            ),
          );
        }),

        const SizedBox(height: 24),

        // FINISH Monument (Right Aligned on Tablet matching Stop 6)
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 28),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MilestoneMonument(
                  type: MilestoneMonumentType.finish,
                  isAllCompleted: isAllCompleted,
                ),
                const SizedBox(width: 14),
                Text(
                  isAllCompleted
                      ? finishText
                      : 'Linux Pathway Milestone Finish',
                  style: TextStyle(
                    color: isAllCompleted
                        ? AppColors.success
                        : AppColors.textSubtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

