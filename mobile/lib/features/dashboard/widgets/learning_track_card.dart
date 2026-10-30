import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../models/learning_path_track.dart';
import 'level_badge.dart';

/// Card for an individual learning path, matching Web's `.dashboard-path-card`.
class LearningTrackCard extends StatelessWidget {
  final LearningPathTrack track;
  final bool isActive;
  final VoidCallback onSelect;

  const LearningTrackCard({
    super.key,
    required this.track,
    required this.isActive,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isGit = track.id == 'git';

    return AppCard(
      borderColor: isActive ? AppColors.lightAccent : null,
      glow: isActive,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  track.title,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              LevelBadge(level: track.level),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            track.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderDefault, height: 1),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.layers_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      track.modules,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              AppButton(
                text: isGit
                    ? 'View Pathway'
                    : (isActive ? 'Active Path' : 'Start Learning'),
                variant: isGit
                    ? ButtonVariant.primary
                    : (isActive ? ButtonVariant.secondary : ButtonVariant.ghost),
                isFullWidth: false,
                height: 38,
                onPressed: onSelect,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
