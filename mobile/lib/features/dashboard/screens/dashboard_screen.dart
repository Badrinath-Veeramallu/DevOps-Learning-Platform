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
    ProgressService().addListener(_onProgressChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id ?? 'guest';
      ProgressService().fetchUserProgress(userId, pathway: 'git');
      ProgressService().fetchUserProgress(userId, pathway: 'docker');
      ProgressService().fetchUserProgress(userId, pathway: 'linux');
      ProgressService().fetchAllPathwaysStatus(userId);
    });
  }

  @override
  void dispose() {
    ProgressService().removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) {
      setState(() {});
    }
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
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    final isUnlocked = ProgressService().isPathwayUnlocked(
      pathway: trackId,
      userId: userId,
    );

    if (!isUnlocked) {
      final reason = ProgressService().getPathwayLockReason(
        pathway: trackId,
        userId: userId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reason ?? 'This pathway is locked. Complete prerequisite pathways to unlock.',
          ),
          backgroundColor: const Color(0xFF92400E),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _activeTrackId = trackId);
    if (trackId == 'git') {
      context.push(RouteNames.gitPathway);
    } else if (trackId == 'docker') {
      context.push(RouteNames.dockerPathway);
    } else if (trackId == 'linux') {
      context.push(RouteNames.linuxPathway);
    }
  }

  void _handleContinue(LearningPathTrack track) {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    final isUnlocked = ProgressService().isPathwayUnlocked(
      pathway: track.id,
      userId: userId,
    );

    if (!isUnlocked) {
      final reason = ProgressService().getPathwayLockReason(
        pathway: track.id,
        userId: userId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reason ?? 'This pathway is locked. Complete prerequisite pathways to unlock.',
          ),
          backgroundColor: const Color(0xFF92400E),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (track.id == 'git') {
      context.push(RouteNames.gitPathway);
    } else if (track.id == 'docker') {
      context.push(RouteNames.dockerPathway);
    } else if (track.id == 'linux') {
      context.push(RouteNames.linuxPathway);
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
        context.push(RouteNames.learningPaths);
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
    final userId = user?.id ?? 'guest';
    final displayName = _resolveDisplayName(user?.name);

    final tracks = LearningPathTrack.defaultTracks;
    final activeTrack = tracks.firstWhere(
      (t) => t.id == _activeTrackId,
      orElse: () => tracks.first,
    );

    final isActiveTrackUnlocked = ProgressService().isPathwayUnlocked(
      pathway: activeTrack.id,
      userId: userId,
    );
    final activeTrackLockReason = ProgressService().getPathwayLockReason(
      pathway: activeTrack.id,
      userId: userId,
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
                isLocked: !isActiveTrackUnlocked,
                lockReason: activeTrackLockReason,
                onContinue: () => _handleContinue(activeTrack),
              ),
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
                'Complete each foundational track sequentially to unlock subsequent intermediate and advanced technologies.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),

              // Tracks List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tracks.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                itemBuilder: (ctx, i) {
                  final track = tracks[i];
                  final isActive = track.id == _activeTrackId;
                  final isUnlocked = ProgressService().isPathwayUnlocked(
                    pathway: track.id,
                    userId: userId,
                  );
                  final lockReason = ProgressService().getPathwayLockReason(
                    pathway: track.id,
                    userId: userId,
                  );

                  return LearningTrackCard(
                    track: track,
                    isActive: isActive,
                    isLocked: !isUnlocked,
                    lockReason: lockReason,
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
