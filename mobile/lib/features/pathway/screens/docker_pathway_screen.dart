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
import '../data/docker_curriculum_repository.dart';
import '../data/progress_service.dart';
import '../widgets/git_pathway_map.dart';
import '../widgets/pathway_header_card.dart';

/// Full Docker Learning Pathway Journey Screen matching Web's `DockerPathwayPage.jsx`.
///
/// Features:
/// - Hero Header Card with completion meter & next-stop hints
/// - Learning Journey section header
/// - Winding S-shaped 7-stop roadmap
/// - Responsive adaptation for mobile phones
/// - Navigation to `/pathways/docker/:moduleId`
class DockerPathwayScreen extends StatefulWidget {
  final List<CurriculumModule>? initialModules;
  final Set<String>? initialCompletedIds;

  const DockerPathwayScreen({
    super.key,
    this.initialModules,
    this.initialCompletedIds,
  });

  @override
  State<DockerPathwayScreen> createState() => _DockerPathwayScreenState();
}

class _DockerPathwayScreenState extends State<DockerPathwayScreen> {
  List<CurriculumModule> _modules = const [];
  Set<String> _completedIds = const {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cached = widget.initialModules ?? DockerCurriculumRepository.cachedModules;
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
        .getCompletedModules(userId, pathway: 'docker')
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

    final cached = DockerCurriculumRepository.cachedModules;
    if (_modules.isEmpty && cached != null && cached.isNotEmpty) {
      setState(() {
        _modules = cached;
        _isLoading = false;
      });
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id ?? 'guest';

      // Warm local completed set immediately
      final localCompleted = await ProgressService().getCompletedModules(userId, pathway: 'docker');
      if (mounted && localCompleted.isNotEmpty && _completedIds.isEmpty) {
        setState(() => _completedIds = localCompleted);
      }

      final modules = await DockerCurriculumRepository.loadCurriculum();
      final completed = widget.initialCompletedIds ??
          await ProgressService()
              .fetchUserProgress(userId, pathway: 'docker');

      if (mounted) {
        setState(() {
          _modules = modules;
          _completedIds = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (_modules.isEmpty) {
          setState(() {
            _error = 'Failed to load Docker curriculum: $e';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _handleSelectModule(String moduleId) {
    if (!ProgressService.isModuleUnlocked(
      pathway: 'docker',
      moduleId: moduleId,
      completedModules: _completedIds,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the previous module to unlock this module.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    context.push('/pathways/docker/$moduleId');
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
    final userId = user?.id ?? 'guest';

    final isUnlocked = (widget.initialModules != null) ||
        ProgressService().isPathwayUnlocked(pathway: 'docker', userId: userId);

    if (!isUnlocked) {
      final lockReason = ProgressService().getPathwayLockReason(
        pathway: 'docker',
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x26B45309),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 36,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      'Pathway Locked',
                      style: AppTypography.badgeText.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Docker & Containerization',
                    textAlign: TextAlign.center,
                    style: AppTypography.displayMedium.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Text(
                      lockReason ?? 'Complete all 7 Git modules to unlock the Docker pathway.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push(RouteNames.gitPathway),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Go to Git Pathway'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _handleBackToDashboard,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMain,
                          side: const BorderSide(color: AppColors.borderDefault),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Back to Dashboard'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null
                ? Center(
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
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pathway Hero Header Card
                        PathwayHeaderCard(
                          completedCount: _modules.where((m) => _completedIds.contains(m.id)).length,
                          totalCount: _modules.length,
                          modules: _modules,
                          completedIds: _completedIds,
                          onBack: _handleBackToDashboard,
                          title: 'Docker & Container Learning Pathway',
                          description:
                              'A structured, visual journey from container isolation and images to multi-stage builds, persistent volumes, networking, and production orchestration.',
                          badgeText: 'Containerization Pathway',
                          allDoneText:
                              "🎉 You've completed all ${_modules.length} Docker stops!",
                        ),
                        const SizedBox(height: 36),

                        // Section Header
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
                                constraints:
                                    const BoxConstraints(maxWidth: 520),
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
                        GitPathwayMap(
                          modules: _modules,
                          completedModuleIds: _completedIds,
                          onSelectModule: _handleSelectModule,
                          onFinishTap: () =>
                              context.push('/pathways/docker/quiz'),
                          finishText:
                              'Containerization & Docker Architecture Mastered!',
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
      ),
    );
  }
}

