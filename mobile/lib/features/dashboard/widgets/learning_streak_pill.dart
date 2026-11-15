import 'package:flutter/material.dart';
import '../../../models/streak_model.dart';

/// Clean, minimal streak pill matching Web's `LearningStreak.jsx` (variant="pill").
/// Displays current streak with active/inactive styling and pending continuation dot.
class LearningStreakPill extends StatelessWidget {
  final StreakModel? streak;
  final bool isLoading;

  const LearningStreakPill({
    super.key,
    this.streak,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: 100,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF5ECEF),
          borderRadius: BorderRadius.circular(9999),
        ),
      );
    }

    final currentStreak = streak?.currentStreak ?? 0;
    final isActiveToday = streak?.isActiveToday ?? false;
    final hasActivityYesterday = streak?.hasActivityYesterday ?? false;
    final isActive = currentStreak > 0;

    final bgColor = isActive ? const Color(0xFFF7EEF0) : const Color(0xFFFCF8F9);
    final borderColor = isActive ? const Color(0xFFE6CFD4) : const Color(0xFFE8DDE0);
    final textColor = isActive ? const Color(0xFF6B3340) : const Color(0xFF60343D);
    final iconColor = isActive ? const Color(0xFF3B1C22) : const Color(0xFFA8A29E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF3B1C22).withValues(alpha: 0.08),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$currentStreak',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            currentStreak == 1 ? 'day streak' : 'days streak',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          if (currentStreak > 0 && !isActiveToday && hasActivityYesterday) ...[
            const SizedBox(width: 5),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF6B3340),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
