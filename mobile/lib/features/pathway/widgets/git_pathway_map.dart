import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/curriculum_model.dart';
import 'milestone_monument.dart';
import 'pathway_stop_node.dart';
import 'pathway_track_painter.dart';

/// Interactive 7-stop Git learning pathway map.
///
/// Features:
/// - Exact Web curriculum order (7 stops)
/// - Connected winding pathway track with layered road cushions & dashed markings
/// - START and FINISH milestone monuments
/// - Responsive adaptation (linear mobile highway on phones, winding alternating S-curves on tablets/wide screens)
/// - Visual state indication: Completed, Current Focus, Upcoming
/// - Direct navigation to `/pathways/git/:moduleId`
class GitPathwayMap extends StatelessWidget {
  final List<CurriculumModule> modules;
  final Set<String> completedModuleIds;
  final ValueChanged<String> onSelectModule;

  const GitPathwayMap({
    super.key,
    required this.modules,
    required this.completedModuleIds,
    required this.onSelectModule,
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

    // Determine current active stop (first non-completed module)
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

  // -------------------------------------------------------------
  // MOBILE ADAPTIVE TIMELINE HIGHWAY (Phones < 720px)
  // -------------------------------------------------------------
  Widget _buildMobileLayout(
    BuildContext context,
    double width,
    int activeIndex,
    bool isAllCompleted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // START Monument
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              child: Center(
                child: MilestoneMonument(type: MilestoneMonumentType.start),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
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
          ],
        ),

        // Road connecting Start to Stop 1
        _buildConnectingRoadSegment(height: 36, isCurved: true),

        // 7 Stops
        ...List.generate(modules.length, (idx) {
          final module = modules[idx];
          final isCompleted = completedModuleIds.contains(module.id);
          final isCurrent = idx == activeIndex && !isCompleted;
          final status = isCompleted
              ? StopStatus.completed
              : (isCurrent ? StopStatus.current : StopStatus.upcoming);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PathwayStopNode(
                module: module,
                status: status,
                onSelectModule: onSelectModule,
              ),
              if (idx < modules.length - 1)
                _buildConnectingRoadSegment(
                  height: 48,
                  isCurved: idx.isEven,
                ),
            ],
          );
        }),

        // Road connecting Stop 7 to Finish
        _buildConnectingRoadSegment(height: 36, isCurved: false),

        // FINISH Monument
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              child: Center(
                child: MilestoneMonument(
                  type: MilestoneMonumentType.finish,
                  isAllCompleted: isAllCompleted,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                isAllCompleted
                    ? 'DevOps Delivery Pipeline Mastered!'
                    : 'Pathway Milestone Finish',
                style: TextStyle(
                  color: isAllCompleted ? AppColors.success : AppColors.textSubtle,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a vertical winding road connection between two milestone nodes on mobile.
  Widget _buildConnectingRoadSegment({
    required double height,
    required bool isCurved,
  }) {
    return SizedBox(
      width: 48,
      height: height,
      child: CustomPaint(
        painter: PathwayTrackPainter(
          points: isCurved
              ? [
                  const Offset(24, 0),
                  Offset(28, height * 0.5),
                  Offset(24, height),
                ]
              : [
                  const Offset(24, 0),
                  Offset(20, height * 0.5),
                  Offset(24, height),
                ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TABLET / DESKTOP WINDING S-CURVE LAYOUT (Width >= 720px)
  // -------------------------------------------------------------
  Widget _buildTabletWindingLayout(
    BuildContext context,
    double width,
    int activeIndex,
    bool isAllCompleted,
  ) {
    return Column(
      children: [
        // START Monument (Left Aligned)
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MilestoneMonument(type: MilestoneMonumentType.start),
                const SizedBox(width: 14),
                Text(
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

        // Alternating 7 Stops
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
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: PathwayStopNode(
                          module: module,
                          status: status,
                          onSelectModule: onSelectModule,
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
                        ),
                      ),
                    ],
            ),
          );
        }),

        const SizedBox(height: 24),

        // FINISH Monument
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 28),
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
                      ? 'DevOps Delivery Pipeline Mastered!'
                      : 'Pathway Milestone Finish',
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
