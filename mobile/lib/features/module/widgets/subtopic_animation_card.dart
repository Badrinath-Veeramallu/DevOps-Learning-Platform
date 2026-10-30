import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/animation_model.dart';
import '../../animations/services/animation_loader.dart';

/// Animation slot component connecting curriculum subtopics to the animation engine.
///
/// Preserves exact subtopic association with `git_animations.json` and prepares
/// the architecture for Phase 5 interactive playback.
class SubtopicAnimationCard extends StatelessWidget {
  final String animationKey;
  final String fallbackTitle;

  const SubtopicAnimationCard({
    super.key,
    required this.animationKey,
    required this.fallbackTitle,
  });

  @override
  Widget build(BuildContext context) {
    final SubtopicAnimation? animation =
        AnimationLoader.findAnimation(animationKey) ??
        AnimationLoader.findAnimation(fallbackTitle);

    if (animation == null) {
      return const SizedBox.shrink();
    }

    final totalSteps = animation.steps.length;
    final String? initialSay =
        animation.steps.isNotEmpty ? animation.steps.first.say : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar matching Web's `.sa-head`
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(
                bottom: BorderSide(color: AppColors.primaryBorder, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.lightAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ANIMATION',
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.lightAccent,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryBorder,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$totalSteps Steps',
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Animation Stage Preview / Presentation
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animation.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (initialSay != null && initialSay.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    initialSay,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Interactive Stage Card Placeholder for Phase 5 Engine
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.borderDefault,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            color: AppColors.lightAccent,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Visual Step Animation Available',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textMain,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Interactive animation model and step engine integrated (Phase 5 playback ready).',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSubtle,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Step Indicators Preview
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          totalSteps.clamp(1, 8),
                          (idx) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: idx == 0
                                  ? AppColors.lightAccent
                                  : AppColors.borderHover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
