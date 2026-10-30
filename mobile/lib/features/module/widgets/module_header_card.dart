import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/curriculum_model.dart';

/// Module Header Card presenting metadata, completion status, title, and summary.
///
/// Matches Web's `.module-top-nav` and `.module-header-card`.
class ModuleHeaderCard extends StatelessWidget {
  final CurriculumModule module;
  final bool isCompleted;
  final VoidCallback onBackToPathway;

  const ModuleHeaderCard({
    super.key,
    required this.module,
    required this.isCompleted,
    required this.onBackToPathway,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Back Navigation Link
        InkWell(
          onTap: onBackToPathway,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
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
                  'Back to Pathway',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.lightAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Metadata Badges Row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Stop Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBorder, width: 1),
              ),
              child: Text(
                'Stop ${module.order} of 7',
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.lightAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Time Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDefault, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${module.estimatedMinutes} min read',
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Verified Done Badge
            if (isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Done',
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Module Title
        Text(
          module.title,
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.textMain,
            fontWeight: FontWeight.w800,
            height: 1.25,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),

        // Module Summary
        Text(
          module.summary,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMuted,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

