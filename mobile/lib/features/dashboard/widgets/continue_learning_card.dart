import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../models/learning_path_track.dart';
import 'level_badge.dart';

/// "Continue Learning" active track card directly mirroring Web's `.continue-learning-card`.
class ContinueLearningCard extends StatelessWidget {
  final LearningPathTrack track;
  final VoidCallback onContinue;

  const ContinueLearningCard({
    super.key,
    required this.track,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isGit = track.id == 'git';

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LevelBadge(level: track.level),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isGit ? 'Interactive Pathway Active' : 'Module in progress',
                  style: AppTypography.bodySmall.copyWith(
                    color: isGit ? AppColors.lightAccent : AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            track.title,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            track.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            text: isGit ? 'Open Pathway' : 'Continue',
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            variant: ButtonVariant.primary,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
