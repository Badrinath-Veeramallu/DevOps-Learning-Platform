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
  final bool isLocked;
  final String? lockReason;
  final VoidCallback onSelect;

  const LearningTrackCard({
    super.key,
    required this.track,
    required this.isActive,
    this.isLocked = false,
    this.lockReason,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasPathway = track.hasPathway;

    return Opacity(
      opacity: isLocked ? 0.85 : 1.0,
      child: AppCard(
        borderColor: isLocked
            ? AppColors.borderDefault
            : (isActive ? AppColors.lightAccent : null),
        glow: isActive && !isLocked,
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
                if (isLocked) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 12,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Locked',
                          style: AppTypography.badgeText.copyWith(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
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
            if (isLocked && lockReason != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_clock_outlined,
                      size: 14,
                      color: Color(0xFF92400E),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        lockReason!,
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFF92400E),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                if (isLocked)
                  AppButton(
                    text: 'Locked',
                    icon: const Icon(Icons.lock_outline, size: 14),
                    variant: ButtonVariant.ghost,
                    isFullWidth: false,
                    height: 38,
                    onPressed: onSelect,
                  )
                else
                  AppButton(
                    text: hasPathway
                        ? 'View Pathway'
                        : (isActive ? 'Active Path' : 'Start Learning'),
                    variant: hasPathway
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
      ),
    );
  }
}
