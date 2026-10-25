import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'cyber_background.dart';
import 'status_badge.dart';

/// Clean scaffold screen for routes implemented in subsequent phases.
///
/// Allows testing Android back navigation, route transitions, and UI consistency.
class PhasePlaceholderScreen extends StatelessWidget {
  final String title;
  final String phaseDescription;
  final String comingInPhase;
  final IconData icon;

  const PhasePlaceholderScreen({
    super.key,
    required this.title,
    required this.phaseDescription,
    required this.comingInPhase,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: CyberBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: AppCard(
              glow: true,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 16),
                  StatusBadge(
                    label: comingInPhase,
                    variant: BadgeVariant.lime,
                    dot: true,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: AppTypography.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    phaseDescription,
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Return to Welcome',
                    variant: ButtonVariant.secondary,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
