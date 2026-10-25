import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/cyber_background.dart';

/// Minimal, clean Welcome Screen.
///
/// Presents the app title and two clear primary actions:
/// 1. Sign In
/// 2. Create Account
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CyberBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primaryBorder,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.terminal_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // App Title
                const Text(
                  'DevOps Learning Platform',
                  style: AppTypography.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Concise Subtitle
                Text(
                  'Master DevOps from code to cloud.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Primary Action: Sign In
                AppButton(
                  text: 'Sign In',
                  variant: ButtonVariant.primary,
                  onPressed: () => context.push(RouteNames.login),
                ),
                const SizedBox(height: 14),

                // Secondary Action: Create Account
                AppButton(
                  text: 'Create Account',
                  variant: ButtonVariant.secondary,
                  onPressed: () => context.push(RouteNames.register),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
