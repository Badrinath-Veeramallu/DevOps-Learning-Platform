import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/curriculum_model.dart';
import 'pathway_track_painter.dart';

enum StopStatus { completed, current, upcoming }

/// Represents a single stop on a learning pathway.
///
/// Contains:
/// 1. Milestone node pin (deep burgundy check, highlighted current, or pale rose upcoming)
/// 2. White light-theme card (title, summary, objectives count, estimated time, status, and action button)
class PathwayStopNode extends StatelessWidget {
  final CurriculumModule module;
  final StopStatus status;
  final ValueChanged<String> onSelectModule;
  final bool isNodeOnly;
  final bool showContinuousRoad;
  final int totalStops;
  final double nodeSize;

  const PathwayStopNode({
    super.key,
    required this.module,
    required this.status,
    required this.onSelectModule,
    this.isNodeOnly = false,
    this.showContinuousRoad = true,
    this.totalStops = 7,
    this.nodeSize = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  /// Builds the circular progress milestone pin matching the website's light burgundy aesthetic.
  Widget buildNodeCircle() {
    final isCompleted = status == StopStatus.completed;
    final isCurrent = status == StopStatus.current;

    final Color bgColor;
    final Color borderColor;
    final Color contentColor;
    final double borderWidth;

    if (isCompleted) {
      bgColor = AppColors.primary;
      borderColor = AppColors.paleBlush;
      contentColor = Colors.white;
      borderWidth = 2.5;
    } else if (isCurrent) {
      bgColor = AppColors.surface;
      borderColor = AppColors.primary;
      contentColor = AppColors.primary;
      borderWidth = 3.5;
    } else {
      bgColor = AppColors.surface;
      borderColor = AppColors.lightAccent;
      contentColor = AppColors.textMuted;
      borderWidth = 2.0;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelectModule(module.id),
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          width: nodeSize,
          height: nodeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              if (isCurrent)
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.28),
                  blurRadius: 12,
                  spreadRadius: 3,
                )
              else if (isCompleted)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              else
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: nodeSize * 0.46,
                  )
                : Text(
                    '${module.order}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: nodeSize * 0.34,
                      fontWeight: FontWeight.w700,
                      color: contentColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Builds the crisp white light-theme module card with burgundy accents.
  Widget buildStopCard(BuildContext context) {
    final isCompleted = status == StopStatus.completed;
    final isCurrent = status == StopStatus.current;

    final Color leftBorderColor;
    final Color cardBg;
    final Color outerBorderColor;
    final double outerBorderWidth;

    if (isCompleted) {
      leftBorderColor = AppColors.secondary;
      cardBg = AppColors.surface;
      outerBorderColor = AppColors.primaryBorder;
      outerBorderWidth = 1.0;
    } else if (isCurrent) {
      leftBorderColor = AppColors.primary;
      cardBg = AppColors.surface;
      outerBorderColor = AppColors.lightAccent;
      outerBorderWidth = 1.25;
    } else {
      leftBorderColor = Colors.transparent;
      cardBg = AppColors.surface;
      outerBorderColor = AppColors.borderDefault;
      outerBorderWidth = 1.0;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.cardShadow,
            blurRadius: isCurrent ? 18 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: outerBorderColor,
              width: outerBorderWidth,
            ),
          ),
          child: Stack(
            children: [
              // Left burgundy accent strip for active and completed stops
              if (isCurrent || isCompleted)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4.5,
                  child: Container(color: leftBorderColor),
                ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top badges & estimated time row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySubtle,
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(
                                  color: AppColors.primaryBorder,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Stop ${module.order} of $totalStops',
                                style: AppTypography.badgeText.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _buildStatusPill(),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: AppColors.textSubtle,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${module.estimatedMinutes} min',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSubtle,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Title
                    InkWell(
                      onTap: () => onSelectModule(module.id),
                      child: Text(
                        module.shortTitle,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Summary
                    Text(
                      module.summary,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Footer Row
                    const Divider(color: AppColors.borderDefault, height: 1),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.assignment_outlined,
                              size: 14,
                              color: AppColors.textSubtle,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${module.objectives.length} Objectives',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSubtle,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        _buildActionButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    switch (status) {
      case StopStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: AppColors.successBorder, width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 11, color: AppColors.successText),
              SizedBox(width: 4),
              Text(
                'Completed',
                style: TextStyle(
                  color: AppColors.successText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      case StopStatus.current:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: const Text(
            'Current Focus',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      case StopStatus.upcoming:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: AppColors.borderDefault, width: 1),
          ),
          child: const Text(
            'Upcoming',
            style: TextStyle(
              color: AppColors.textSubtle,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
  }

  Widget _buildActionButton() {
    final String label;
    final IconData icon;
    final Color btnBg;
    final Color btnBorder;
    final Color textColor;

    switch (status) {
      case StopStatus.completed:
        label = 'Review Module';
        icon = Icons.replay_rounded;
        btnBg = AppColors.primarySubtle;
        btnBorder = AppColors.primaryBorder;
        textColor = AppColors.primary;
        break;
      case StopStatus.current:
        label = 'Start Learning';
        icon = Icons.arrow_forward_rounded;
        btnBg = AppColors.primary;
        btnBorder = AppColors.primary;
        textColor = Colors.white;
        break;
      case StopStatus.upcoming:
        label = 'Explore Stop';
        icon = Icons.arrow_forward_ios_rounded;
        btnBg = AppColors.surface;
        btnBorder = AppColors.borderDefault;
        textColor = AppColors.textMuted;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelectModule(module.id),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: btnBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: btnBorder, width: 1),
            boxShadow: status == StopStatus.current
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.buttonText.copyWith(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 5),
              Icon(icon, size: 13, color: textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isNodeOnly) {
      return buildNodeCircle();
    }

    if (!showContinuousRoad) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: buildNodeCircle(),
          ),
          const SizedBox(width: 14),
          Expanded(child: buildStopCard(context)),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: PathwayRoadGeometry.laneWidth,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: ContinuousRoadSegmentPainter(
                      moduleIndex: module.order - 1,
                    ),
                  ),
                ),
                Positioned(
                  left: PathwayRoadGeometry.getNodeX(module.order - 1) - 24,
                  top: 8,
                  child: buildNodeCircle(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: buildStopCard(context),
            ),
          ),
        ],
      ),
    );
  }
}
