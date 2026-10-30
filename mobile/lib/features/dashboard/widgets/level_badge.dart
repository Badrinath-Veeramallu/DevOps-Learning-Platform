import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Reusable difficulty level badge matching Web's `.badge-pill`.
class LevelBadge extends StatelessWidget {
  final String level;

  const LevelBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Text(
        level,
        style: AppTypography.badgeText.copyWith(
          color: colors.text,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  ({Color bg, Color border, Color text}) _resolveColors() {
    switch (level.toLowerCase()) {
      case 'foundational':
        return (
          bg: const Color(0xFF1E293B),
          border: AppColors.secondaryBorder,
          text: AppColors.lightAccent,
        );
      case 'intermediate':
        return (
          bg: AppColors.primarySubtle,
          border: AppColors.primaryBorder,
          text: AppColors.subtleHighlight,
        );
      case 'advanced':
        return (
          bg: AppColors.secondaryActive,
          border: AppColors.secondary,
          text: AppColors.textMain,
        );
      default:
        return (
          bg: AppColors.surfaceElevated,
          border: AppColors.borderDefault,
          text: AppColors.textMuted,
        );
    }
  }
}

