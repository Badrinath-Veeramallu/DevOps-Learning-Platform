import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/curriculum_model.dart';

/// Navigation footer supporting subtopic progression, module completion, and pathway navigation.
class SubtopicNavFooter extends StatelessWidget {
  final int currentSubtopicIndex;
  final int totalSubtopics;
  final CurriculumModule currentModule;
  final CurriculumModule? prevModule;
  final CurriculumModule? nextModule;
  final bool isCompleted;
  final VoidCallback onPrevSubtopic;
  final VoidCallback onNextSubtopic;
  final VoidCallback onToggleComplete;
  final ValueChanged<String> onNavigateModule;
  final VoidCallback onReturnToPathway;

  const SubtopicNavFooter({
    super.key,
    required this.currentSubtopicIndex,
    required this.totalSubtopics,
    required this.currentModule,
    this.prevModule,
    this.nextModule,
    required this.isCompleted,
    required this.onPrevSubtopic,
    required this.onNextSubtopic,
    required this.onToggleComplete,
    required this.onNavigateModule,
    required this.onReturnToPathway,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPrevSubtopic = currentSubtopicIndex > 0;
    final bool hasNextSubtopic = currentSubtopicIndex < totalSubtopics - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),

        // 1. Subtopic Previous / Next Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryBorder, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Subtopic Button
              TextButton.icon(
                onPressed: hasPrevSubtopic ? onPrevSubtopic : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 14),
                label: const Text('Prev'),
                style: TextButton.styleFrom(
                  foregroundColor: hasPrevSubtopic
                      ? AppColors.lightAccent
                      : AppColors.textSubtle,
                  disabledForegroundColor:
                      AppColors.textSubtle.withValues(alpha: 0.4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),

              // Current Subtopic Indicator
              Flexible(
                child: Text(
                  'Subtopic ${currentSubtopicIndex + 1} of $totalSubtopics',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),

              // Next Subtopic Button
              TextButton.icon(
                onPressed: hasNextSubtopic ? onNextSubtopic : null,
                icon: const Text('Next'),
                label: const Icon(Icons.arrow_forward_rounded, size: 14),
                style: TextButton.styleFrom(
                  foregroundColor: hasNextSubtopic
                      ? AppColors.lightAccent
                      : AppColors.textSubtle,
                  disabledForegroundColor:
                      AppColors.textSubtle.withValues(alpha: 0.4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 2. Module Completion Card matching Web's `.module-footer-completion`
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.5)
                  : AppColors.primaryBorder,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ready to advance?',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isCompleted
                    ? 'You have completed this stop! Proceed to the next module or return to the pathway.'
                    : 'Mark this module as completed to record your progress along the learning pathway.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),

              // Large Toggle Complete Button
              ElevatedButton.icon(
                onPressed: onToggleComplete,
                icon: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 18,
                ),
                label: Text(
                  isCompleted
                      ? 'Completed (Click to Undo)'
                      : 'Mark Stop as Completed',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.primary,
                  foregroundColor: isCompleted
                      ? AppColors.success
                      : Colors.white,
                  side: isCompleted
                      ? const BorderSide(color: AppColors.success, width: 1.2)
                      : BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Module Previous / Overview / Next Navigation
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 10,
          children: [
            if (prevModule != null)
              OutlinedButton(
                onPressed: () => onNavigateModule(prevModule!.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.borderDefault),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Stop ${prevModule!.order}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            OutlinedButton.icon(
              onPressed: onReturnToPathway,
              icon: const Icon(Icons.map_outlined, size: 14),
              label: const Text(
                'Pathway',
                style: TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.lightAccent,
                side: const BorderSide(color: AppColors.primaryBorder),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),

            if (nextModule != null)
              ElevatedButton(
                onPressed: () => onNavigateModule(nextModule!.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.lightAccent,
                  side: const BorderSide(color: AppColors.primaryBorder),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Stop ${nextModule!.order}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
