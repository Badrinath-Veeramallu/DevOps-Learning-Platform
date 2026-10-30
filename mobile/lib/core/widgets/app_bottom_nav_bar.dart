import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Bottom Navigation Bar tailored for mobile with clear active indicators.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.borderDefault, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Center(
                  heightFactor: 1.0,
                  child: _buildNavItem(
                    index: 0,
                    label: 'Dashboard',
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  heightFactor: 1.0,
                  child: _buildNavItem(
                    index: 1,
                    label: 'Git Pathway',
                    icon: Icons.alt_route_outlined,
                    activeIcon: Icons.alt_route_rounded,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  heightFactor: 1.0,
                  child: _buildNavItem(
                    index: 2,
                    label: 'Profile',
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final bool isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primaryBorder, width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? AppColors.lightAccent : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.lightAccent : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
