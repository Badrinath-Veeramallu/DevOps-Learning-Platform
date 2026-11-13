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
import '../widgets/learning_track_card.dart';

/// Screen listing all available DevOps learning tracks (Git, Docker, CI/CD, etc.).
class LearningPathsScreen extends StatefulWidget {
  const LearningPathsScreen({super.key});

  @override
  State<LearningPathsScreen> createState() => _LearningPathsScreenState();
}

class _LearningPathsScreenState extends State<LearningPathsScreen> {
  String _activeTrackId = 'git';

  @override
  void initState() {
    super.initState();
    ProgressService().addListener(_onProgressChanged);
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$trackId learning pathway is coming soon!'),
          backgroundColor: AppColors.surfaceElevated,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.dashboard);
        break;
      case 1:
        // Already on Learning Paths
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
    final tracks = LearningPathTrack.defaultTracks;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeaderBar(
        user: user,
        authProvider: authProvider,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onTabSelected: _handleBottomNavTap,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Learning Paths',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Explore hands-on interactive pathways to master DevOps practices from code to cloud.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
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
