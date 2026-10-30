import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/curriculum_model.dart';

enum StopStatus { completed, current, upcoming }

/// Represents a single stop on the Git learning pathway.
///
/// Contains:
/// 1. Milestone node pin (circle with order number or checkmark)
/// 2. Rich subtopic card (title, summary, objectives count, estimated time, and action button)
class PathwayStopNode extends StatelessWidget {
  final CurriculumModule module;
  final StopStatus status;
  final ValueChanged<String> onSelectModule;
  final bool isNodeOnly;

  const PathwayStopNode({
    super.key,
    required this.module,
    required this.status,
    required this.onSelectModule,
    this.isNodeOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  /// Builds the milestone pin circle.
  Widget buildNodeCircle() {
    final isCompleted = status == StopStatus.completed;
    final isCurrent = status == StopStatus.current;

    Color bgColor;
    Color borderColor;
    Color contentColor;
    double borderWidth;

    if (isCompleted) {
      bgColor = AppColors.primary;
      borderColor = AppColors.lightAccent;
      contentColor = Colors.white;
      borderWidth = 2.5;
    } else if (isCurrent) {
      bgColor = AppColors.surfaceElevated;
      borderColor = AppColors.lightAccent;
      contentColor = AppColors.textMain;
      borderWidth = 3.5;
    } else {
      bgColor = AppColors.surface;
      borderColor = AppColors.borderDefault;
      contentColor = AppColors.textMuted;
      borderWidth = 2.0;
    }

    return InkWell(
      onTap: () => onSelectModule(module.id),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            if (isCurrent)
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 2,
              )
            else if (isCompleted)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Center(
          child: isCompleted
              ? const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 22,
                )
              : Text(
                  '${module.order}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: contentColor,
                  ),
                ),
        ),
      ),
    );
  }

  /// Builds the rich subtopic card.
  Widget buildStopCard(BuildContext context) {
    final isCompleted = status == StopStatus.completed;
    final isCurrent = status == StopStatus.current;

    Color leftBorderColor;
    Color cardBg;
    Color outerBorderColor;

    if (isCompleted) {
      leftBorderColor = AppColors.accent;
      cardBg = AppColors.surface;
      outerBorderColor = AppColors.borderDefault;
    } else if (isCurrent) {
      leftBorderColor = AppColors.lightAccent;
      cardBg = AppColors.surfaceElevated;
      outerBorderColor = AppColors.primaryLight;
    } else {
      leftBorderColor = Colors.transparent;
      cardBg = AppColors.surface;
      outerBorderColor = AppColors.borderDefault;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: outerBorderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Left Accent Strip (matches Web left border)
            if (isCurrent || isCompleted)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4.5,
                child: Container(color: leftBorderColor),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Badges & Est Time Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Badge Row
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
                            ),
                            child: Text(
                              'Stop ${module.order} of 7',
                              style: AppTypography.badgeText.copyWith(
                                color: AppColors.lightAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _buildStatusPill(),
                        ],
                      ),

                      // Estimated time
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
                  const SizedBox(height: 12),

                  // Title
                  InkWell(
                    onTap: () => onSelectModule(module.id),
                    child: Text(
                      module.shortTitle,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Summary
                  Text(
                    module.summary,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Footer Row
                  const Divider(color: AppColors.borderDefault, height: 1),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Objectives count
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

                      // Action button
                      _buildActionButton(),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
            color: const Color(0x1F10B981),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: const Color(0x5910B981), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 11, color: Color(0xFF10B981)),
              SizedBox(width: 4),
              Text(
                'Completed',
                style: TextStyle(
                  color: Color(0xFF10B981),
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
            border: Border.all(color: AppColors.primaryLight, width: 1),
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
            color: AppColors.surfaceElevated,
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
        btnBg = AppColors.surfaceElevated;
        btnBorder = AppColors.borderDefault;
        textColor = AppColors.lightAccent;
        break;
      case StopStatus.current:
        label = 'Start Learning';
        icon = Icons.arrow_forward_rounded;
        btnBg = AppColors.primary;
        btnBorder = AppColors.primaryLight;
        textColor = Colors.white;
        break;
      case StopStatus.upcoming:
        label = 'Explore Stop';
        icon = Icons.arrow_forward_ios_rounded;
        btnBg = Colors.transparent;
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
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.buttonText.copyWith(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
}
