import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum BadgeVariant { cyan, lime, indigo, warning, error }

/// Reusable status badge matching the web application's badge component.
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final bool dot;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.cyan,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getBadgeColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.badgeText.copyWith(color: colors.text),
          ),
        ],
      ),
    );
  }

  ({Color bg, Color border, Color accent, Color text}) _getBadgeColors() {
    switch (variant) {
      case BadgeVariant.cyan:
        return (
          bg: AppColors.primarySubtle,
          border: AppColors.primaryBorder,
          accent: AppColors.accent,
          text: AppColors.subtleHighlight,
        );
      case BadgeVariant.lime:
        return (
          bg: AppColors.secondarySubtle,
          border: AppColors.secondaryBorder,
          accent: AppColors.lightAccent,
          text: AppColors.subtleHighlight,
        );
      case BadgeVariant.indigo:
        return (
          bg: AppColors.indigoSubtle,
          border: AppColors.indigoBorder,
          accent: AppColors.accent,
          text: AppColors.lightAccent,
        );
      case BadgeVariant.warning:
        return (
          bg: AppColors.warningBg,
          border: AppColors.warningBorder,
          accent: AppColors.warning,
          text: const Color(0xFFFDE68A),
        );
      case BadgeVariant.error:
        return (
          bg: AppColors.errorBg,
          border: AppColors.errorBorder,
          accent: AppColors.error,
          text: const Color(0xFFFCA5A5),
        );
    }
  }
}
