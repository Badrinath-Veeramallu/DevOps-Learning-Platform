import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

enum MilestoneMonumentType { start, finish }

/// Displays the START or FINISH milestone monument along the pathway road.
///
/// Matches Web's `.pathway-endpoint-monument` styling with circular emblem
/// and high-contrast uppercase badge.
class MilestoneMonument extends StatelessWidget {
  final MilestoneMonumentType type;
  final bool isAllCompleted;

  const MilestoneMonument({
    super.key,
    required this.type,
    this.isAllCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isStart = type == MilestoneMonumentType.start;
    final isFinishDone = !isStart && isAllCompleted;

    // Circle colors
    final circleBg = isStart
        ? Colors.white
        : (isFinishDone ? const Color(0xFF15803D) : AppColors.primary);
    final circleBorder = isStart
        ? AppColors.primary
        : (isFinishDone ? Colors.white : Colors.white);
    final iconColor = isStart
        ? AppColors.primary
        : Colors.white;

    // Pill badge colors
    final pillBg = isStart
        ? const Color(0xFFF5ECEF)
        : (isFinishDone ? const Color(0xFF15803D) : AppColors.primary);
    final pillTextColor = isStart ? AppColors.primary : Colors.white;
    final pillBorder = isStart
        ? const Color(0xFFE8DDE0)
        : (isFinishDone ? const Color(0xFF15803D) : AppColors.primary);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Emblem circle
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleBg,
            border: Border.all(color: circleBorder, width: 3),
            boxShadow: [
              BoxShadow(
                color: isFinishDone
                    ? const Color(0xFF15803D).withValues(alpha: 0.35)
                    : AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: isStart
                ? Icon(Icons.flag_rounded, color: iconColor, size: 24)
                : Icon(
                    isFinishDone ? Icons.sports_score_rounded : Icons.outlined_flag_rounded,
                    color: iconColor,
                    size: 24,
                  ),
          ),
        ),
        const SizedBox(height: 6),

        // Text Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: pillBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            isStart ? 'START' : 'FINISH',
            style: AppTypography.badgeText.copyWith(
              color: pillTextColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
