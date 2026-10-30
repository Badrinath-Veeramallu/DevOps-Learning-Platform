import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/curriculum_model.dart';

/// Hero header card for the Git Pathway screen matching Web's `.pathway-header-card`.
///
/// Displays:
/// - "Back to Dashboard" link
/// - Badges: "Foundational Pathway", "7 Interactive Stops"
/// - Title & description
/// - Progress meter with fraction, fill bar, and next-stop hint
class PathwayHeaderCard extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final List<CurriculumModule> modules;
  final Set<String> completedIds;
  final VoidCallback onBack;

  const PathwayHeaderCard({
    super.key,
    required this.completedCount,
    required this.totalCount,
    required this.modules,
    required this.completedIds,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = totalCount > 0
        ? ((completedCount / totalCount) * 100).round()
        : 0;

    // Find next uncompleted module
    CurriculumModule? nextModule;
    int nextIndex = 1;
    for (int i = 0; i < modules.length; i++) {
      if (!completedIds.contains(modules[i].id)) {
        nextModule = modules[i];
        nextIndex = i + 1;
        break;
      }
    }

    final bool isAllDone = totalCount > 0 && completedCount >= totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Navigation Link
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: AppColors.lightAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Back to Dashboard',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.lightAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Main Header Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Pill Row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
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
                      'Foundational Pathway',
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.lightAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: AppColors.borderDefault,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$totalCount Interactive Stops',
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                'Git & GitHub Learning Pathway',
                style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                  fontSize: 22,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'A structured, visual journey from fundamental version control commands to team collaboration, conflict resolution, and automated DevOps delivery pipelines.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // Progress Overview Panel
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDefault, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'PATHWAY PROGRESS',
                          style: AppTypography.badgeText.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: '$completedCount',
                                style: const TextStyle(
                                  color: AppColors.textMain,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: ' of $totalCount Completed ($progressPercent%)',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Progress Track & Fill
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: LinearProgressIndicator(
                        value: totalCount > 0 ? completedCount / totalCount : 0.0,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Foot Hint
                    Text(
                      isAllDone
                          ? "🎉 You've completed all $totalCount Git & GitHub stops!"
                          : (nextModule != null
                              ? 'Next: Stop $nextIndex · ${nextModule.shortTitle}'
                              : 'All stops completed!'),
                      style: AppTypography.bodySmall.copyWith(
                        color: isAllDone
                            ? AppColors.success
                            : AppColors.lightAccent,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
