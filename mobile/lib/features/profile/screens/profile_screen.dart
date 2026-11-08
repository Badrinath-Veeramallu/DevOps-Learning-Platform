import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header_bar.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/activity_heatmap.dart';

/// Full feature and UI parity Profile Screen matching Web's `Profile.jsx`.
///
/// Features:
/// - Account details (Avatar, Name, Email, Auth method, Member since)
/// - Inline Name Editing via `authProvider.updateProfile(name)`
/// - 52-week Learning Activity Heatmap backed by `/api/activity?tz=...`
/// - Persistent bottom navigation bar and account logout
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditingName = false;
  late final TextEditingController _nameController;
  bool _isSavingName = false;
  String? _nameError;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController = TextEditingController(text: authProvider.user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleStartEdit() {
    final authProvider = context.read<AuthProvider>();
    _nameController.text = authProvider.user?.name ?? '';
    setState(() {
      _isEditingName = true;
      _nameError = null;
      _successMessage = null;
    });
  }

  void _handleCancelEdit() {
    final authProvider = context.read<AuthProvider>();
    _nameController.text = authProvider.user?.name ?? '';
    setState(() {
      _isEditingName = false;
      _nameError = null;
    });
  }

  Future<void> _handleSaveProfile() async {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _nameError = 'Full name is required.');
      return;
    }
    if (trimmed.length < 2) {
      setState(() => _nameError = 'Name must be at least 2 characters long.');
      return;
    }

    setState(() {
      _isSavingName = true;
      _nameError = null;
      _successMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.updateProfile(name: trimmed);
      if (mounted) {
        setState(() {
          _isEditingName = false;
          _isSavingName = false;
          _successMessage = 'Profile name updated successfully.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingName = false;
          _nameError = 'Failed to update profile name: $e';
        });
      }
    }
  }

  void _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (mounted) {
      context.go(RouteNames.welcome);
    }
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        context.push(RouteNames.dashboard);
        break;
      case 1:
        context.push(RouteNames.gitPathway);
        break;
      case 2:
        // Already on Profile
        break;
    }
  }

  String _formatMemberSince(DateTime? createdAt) {
    if (createdAt == null) return 'N/A';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final month = months[createdAt.month - 1];
    return '$month ${createdAt.day}, ${createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final initials = user?.name.isNotEmpty == true
        ? user!.name
            .trim()
            .split(RegExp(r'\s+'))
            .map((p) => p.isEmpty ? '' : p[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    final authMethod = user?.authProvider == 'google'
        ? 'Google Account'
        : 'Email & Password';

    final memberSince = _formatMemberSince(user?.createdAt);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeaderBar(
        user: user,
        authProvider: authProvider,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTabSelected: _handleBottomNavTap,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Back Navigation
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(RouteNames.dashboard);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                  label: const Text('Back to Dashboard'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.lightAccent,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Page Title & Subtitle
              Text(
                'My Profile',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your account and learning activity.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // Feedback alerts
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.successBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_nameError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.errorBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _nameError!,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // User Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar & Basic Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            initials,
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.subtleHighlight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Learner',
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.textMain,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? 'Not signed in',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.borderDefault, height: 1),
                    const SizedBox(height: 16),

                    // Full Name Editing Row
                    if (_isEditingName) ...[
                      Text(
                        'Full Name',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.textMain),
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          hintStyle: const TextStyle(color: AppColors.textSubtle),
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.borderDefault),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.lightAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _isSavingName ? null : _handleSaveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: _isSavingName
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Save'),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: _isSavingName ? null : _handleCancelEdit,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textMuted,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildInfoRow(
                        label: 'Full Name',
                        value: user?.name ?? 'Learner',
                        trailing: TextButton(
                          onPressed: _handleStartEdit,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.lightAccent,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Edit'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    _buildInfoRow(label: 'Email Address', value: user?.email ?? '—'),
                    const SizedBox(height: 14),
                    _buildInfoRow(label: 'Sign-in Method', value: authMethod),
                    const SizedBox(height: 14),
                    _buildInfoRow(label: 'Member Since', value: memberSince),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 52-Week Learning Activity Heatmap
              ActivityHeatmap(apiClient: authProvider.apiClient),

              const SizedBox(height: 24),

              // Logout Button
              AppButton(
                text: 'Sign Out',
                icon: const Icon(Icons.logout_rounded, size: 18),
                variant: ButtonVariant.ghost,
                onPressed: _handleLogout,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSubtle,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        ?trailing,
      ],
    );
  }
}
