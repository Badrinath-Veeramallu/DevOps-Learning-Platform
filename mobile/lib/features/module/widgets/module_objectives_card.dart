import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Learning Objectives Card matching Web's `.module-objectives-card`.
class ModuleObjectivesCard extends StatelessWidget {
  final List<String> objectives;

  const ModuleObjectivesCard({
    super.key,
    required this.objectives,
  });

  @override
  Widget build(BuildContext context) {
    if (objectives.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.primary, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.track_changes_rounded,
                      size: 18,
                      color: AppColors.lightAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Objectives',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Objectives items
              ...objectives.map(
                (obj) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          obj,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMain,
                            height: 1.45,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

