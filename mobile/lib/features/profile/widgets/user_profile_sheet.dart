import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

/// Modal bottom sheet mimicking Web's `UserProfileMenu.jsx` for mobile screens.
class UserProfileSheet extends StatelessWidget {
  final UserModel user;
  final AuthProvider authProvider;

  const UserProfileSheet({
    super.key,
    required this.user,
    required this.authProvider,
  });

  static void show(
    BuildContext context, {
    required UserModel user,
    required AuthProvider authProvider,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.primaryBorder, width: 1),
      ),
      builder: (ctx) => UserProfileSheet(user: user, authProvider: authProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').map((p) => p.isEmpty ? '' : p[0]).take(2).join().toUpperCase()
        : 'U';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.borderHover,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // User Header Info
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initials,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.subtleHighlight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySubtle,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.primaryBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              user.isEmailVerified ? 'Verified' : 'Unverified',
                              style: AppTypography.bodySmall.copyWith(
                                color: user.isEmailVerified
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user.authProvider == 'google'
                                ? 'Google Account'
                                : 'Email & Password',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSubtle,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.borderDefault, height: 1),
            const SizedBox(height: 12),
            // Actions matching Web's dropdown
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.lightAccent,
                size: 22,
              ),
              title: Text(
                'My Profile',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.push(RouteNames.profile);
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 22,
              ),
              title: Text(
                'Sign Out',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await authProvider.logout();
                if (context.mounted) {
                  context.go(RouteNames.welcome);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
