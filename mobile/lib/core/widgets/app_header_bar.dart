import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../features/profile/widgets/user_profile_sheet.dart';

/// Top Application Header Bar matching Web's `Navbar.jsx`.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final UserModel? user;
  final AuthProvider authProvider;
  final bool showProfileAvatar;

  const AppHeaderBar({
    super.key,
    required this.user,
    required this.authProvider,
    this.showProfileAvatar = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final initials = user?.name.isNotEmpty == true
        ? user!.name.trim().split(' ').map((p) => p.isEmpty ? '' : p[0]).take(2).join().toUpperCase()
        : 'U';

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      toolbarHeight: 60,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryBorder, width: 1),
            ),
            child: const Icon(
              Icons.terminal_rounded,
              color: AppColors.lightAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'DevOps ',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: 'Platform',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.lightAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (showProfileAvatar && user != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryBorder, width: 1.5),
              ),
              child: GestureDetector(
                key: const Key('profile_avatar_button'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  UserProfileSheet.show(
                    context,
                    user: user!,
                    authProvider: authProvider,
                  );
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initials,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.subtleHighlight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.borderDefault,
          height: 1,
        ),
      ),
    );
  }
}
