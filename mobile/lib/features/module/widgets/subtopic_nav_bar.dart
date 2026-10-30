import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/curriculum_model.dart';

/// Horizontal subtopic selector for fast, comfortable section jumping on mobile.
class SubtopicNavBar extends StatelessWidget {
  final List<CurriculumSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelectSubtopic;

  const SubtopicNavBar({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onSelectSubtopic,
  });

  String _cleanSubtopicTitle(String rawTitle) {
    // Strip leading number prefix like "1. " if present for compact chip display
    return rawTitle.replaceFirst(RegExp(r'^\d+\.\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SUBTOPICS',
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.lightAccent,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${selectedIndex + 1} of ${sections.length}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSubtle,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Horizontal Scrolling Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(sections.length, (index) {
              final section = sections[index];
              final isSelected = selectedIndex == index;
              final title = _cleanSubtopicTitle(section.title);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onSelectSubtopic(index),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primarySubtle
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.lightAccent
                            : AppColors.primaryBorder,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.lightAccent
                                : AppColors.surfaceElevated,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${section.number}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.background
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: AppTypography.bodySmall.copyWith(
                            color: isSelected
                                ? AppColors.textMain
                                : AppColors.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

