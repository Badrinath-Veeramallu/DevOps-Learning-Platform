import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/app_header_bar.dart';
import '../../../models/curriculum_model.dart';
import '../../../providers/auth_provider.dart';
import '../../animations/services/animation_loader.dart';
import '../data/linux_curriculum_repository.dart';
import '../data/progress_service.dart';
import '../widgets/linux_pathway_map.dart';
import '../widgets/pathway_header_card.dart';

/// Full Linux Learning Pathway Journey Screen matching Web's `LinuxPathwayPage.jsx`.
///
/// Features:
/// - Hero Header Card with completion meter & next-stop hints
/// - Learning Journey section header
/// - Winding S-shaped 6-stop roadmap
/// - Responsive adaptation for mobile phones
/// - Navigation to `/pathways/linux/:moduleId`
class LinuxPathwayScreen extends StatefulWidget {
  final List<CurriculumModule>? initialModules;
  final Set<String>? initialCompletedIds;

  const LinuxPathwayScreen({
    super.key,
    this.initialModules,
    this.initialCompletedIds,
  });

  @override
  State<LinuxPathwayScreen> createState() => _LinuxPathwayScreenState();
}

class _LinuxPathwayScreenState extends State<LinuxPathwayScreen> {
  List<CurriculumModule> _modules = const [];
  Set<String> _completedIds = const {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-warm Linux animations in background so they are instantly ready upon entering modules
    if (AnimationLoader.cachedModules(pathway: 'linux') == null) {
      AnimationLoader.loadAnimations(pathway: 'linux').catchError((e) {
        debugPrint('[LinuxPathwayScreen] Preloading animations error: $e');
        return <Never>[];
      });
    }
    final cached = widget.initialModules ?? LinuxCurriculumRepository.cachedModules;
    if (cached != null && cached.isNotEmpty) {
      _modules = cached;
      _completedIds = widget.initialCompletedIds ?? const {};
      _isLoading = false;
    }
    _loadData();
    ProgressService().addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    ProgressService().removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    ProgressService()
        .getCompletedModules(userId, pathway: 'linux')
        .then((completed) {
      if (mounted) {
        setState(() => _completedIds = completed);
      }
    });
  }

  Future<void> _loadData() async {
    if (widget.initialModules != null) {
      setState(() {
        _modules = widget.initialModules!;
        _completedIds = widget.initialCompletedIds ?? const {};
        _isLoading = false;
      });
      return;
    }

    final cached = LinuxCurriculumRepository.cachedModules;
    if (_modules.isEmpty && cached != null && cached.isNotEmpty) {
      setState(() {
        _modules = cached;
        _isLoading = false;
      });
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id ?? 'guest';

      final localCompleted =
          await ProgressService().getCompletedModules(userId, pathway: 'linux');
      if (mounted && localCompleted.isNotEmpty && _completedIds.isEmpty) {
        setState(() => _completedIds = localCompleted);
      }

      final modules = await LinuxCurriculumRepository.loadCurriculum();

      if (mounted) {
        setState(() {
          _modules = modules;
          if (_completedIds.isEmpty) {
            _completedIds = localCompleted;
          }
          _isLoading = false;
          _error = null;
        });
      }

      final serverCompleted =
          await ProgressService().fetchUserProgress(userId, pathway: 'linux');
      if (mounted) {
        setState(() => _completedIds = serverCompleted);
      }
    } catch (e) {
      if (mounted && _modules.isEmpty) {
        setState(() {
          _error = 'Failed to load Linux curriculum: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _handleSelectModule(String moduleId) {
    context.push('/pathways/linux/$moduleId');
  }

  void _handleBackToDashboard() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.dashboard);
    }
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.dashboard);
        break;
      case 1:
        context.go(RouteNames.learningPaths);
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
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null && _modules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () async {
        final authProvider = context.read<AuthProvider>();
        final userId = authProvider.user?.id ?? 'guest';
        final updated =
            await ProgressService().fetchUserProgress(userId, pathway: 'linux');
        if (mounted) {
          setState(() => _completedIds = updated);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pathway Hero Header Card
            PathwayHeaderCard(
              completedCount: _completedIds.length,
              totalCount: _modules.length,
              modules: _modules,
              completedIds: _completedIds,
              onBack: _handleBackToDashboard,
              title: 'Linux Essentials Pathway',
              description:
                  'A progressive, step-by-step interactive map guiding you through Linux file systems, permissions, process and service management, networking, package administration, and shell scripting automation.',
              badgeText: 'Foundational Pathway',
              allDoneText:
                  '🎉 You have completed all stops in this pathway! Excellent work.',
            ),
            const SizedBox(height: 36),

            // Section Header matching Git and Docker
            Center(
              child: Column(
                children: [
                  Text(
                    'Learning Journey',
                    style: AppTypography.displayMedium.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(
                      'Click any stop along the path to open its complete educational module, commands, and interactive visual slots.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        height: 1.45,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Winding Pathway Roadmap
            LinuxPathwayMap(
              modules: _modules,
              completedModuleIds: _completedIds,
              onSelectModule: _handleSelectModule,
              finishText: 'Linux System Administration Mastered!',
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
