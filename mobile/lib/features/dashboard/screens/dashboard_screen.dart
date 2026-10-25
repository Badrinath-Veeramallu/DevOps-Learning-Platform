import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';

/// Minimal post-login screen displaying a dynamic user greeting and logout action.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _resolveDisplayName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'Developer';
    }
    final trimmed = fullName.trim();
    final first = trimmed.split(RegExp(r'\s+')).first;
    if (first.isEmpty) return 'Developer';
    return first[0].toUpperCase() + first.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final displayName = _resolveDisplayName(user?.name);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $displayName 👋',
                          style: AppTypography.displayMedium.copyWith(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Welcome back!',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                    tooltip: 'Sign Out',
                    onPressed: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go(RouteNames.welcome);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
