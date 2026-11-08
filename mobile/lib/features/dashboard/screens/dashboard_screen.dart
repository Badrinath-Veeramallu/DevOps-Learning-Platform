import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/app_header_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../pathway/data/progress_service.dart';
import '../../profile/widgets/activity_heatmap.dart';
import '../models/learning_path_track.dart';
import '../widgets/continue_learning_card.dart';
import '../widgets/learning_track_card.dart';

/// Full feature and UI parity Dashboard matching Web's `Dashboard.jsx`.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _activeTrackId = 'git';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id ?? 'guest';
      ProgressService().fetchUserProgress(userId);
    });
  }

  String _resolveDisplayName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'Learner';
    }
    final trimmed = fullName.trim();
    final first = trimmed.split(RegExp(r'\s+')).first;
    if (first.isEmpty) return 'Learner';
    return first[0].toUpperCase() + first.substring(1);
  }

  void _handleSelectTrack(String trackId) {
    setState(() => _activeTrackId = trackId);
    if (trackId == 'git') {
      context.push(RouteNames.gitPathway);
    }
  }

  void _handleContinue(LearningPathTrack track) {
    if (track.id == 'git') {
      context.push(RouteNames.gitPathway);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Continuing ${track.title}'),
          backgroundColor: AppColors.surfaceElevated,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Already on Dashboard
        break;
      case 1:
        context.push(RouteNames.gitPathway);
        break;
      case 2:
        context.push(RouteNames.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final displayName = _resolveDisplayName(user?.name);

    final tracks = LearningPathTrack.defaultTracks;
    final activeTrack = tracks.firstWhere(
      (t) => t.id == _activeTrackId,
      orElse: () => tracks.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeaderBar(
        user: user,
        authProvider: authProvider,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTabSelected: _handleBottomNavTap,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Text(
                'Welcome back, $displayName',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Continue learning or choose a learning path to get started.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Continue Learning Section
              Text(
                'Continue Learning',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              ContinueLearningCard(
                track: activeTrack,
                onContinue: () => _handleContinue(activeTrack),
              ),
              const SizedBox(height: 24),

              // Activity Heatmap
              ActivityHeatmap(apiClient: authProvider.apiClient),
              const SizedBox(height: 32),

              // Available Learning Paths Section
              Text(
                'Available Learning Paths',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a path to build practical skills across the DevOps lifecycle.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),

              // 6 Tracks List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tracks.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                itemBuilder: (ctx, i) {
                  final track = tracks[i];
                  final isActive = track.id == _activeTrackId;
                  return LearningTrackCard(
                    track: track,
                    isActive: isActive,
                    onSelect: () => _handleSelectTrack(track.id),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
