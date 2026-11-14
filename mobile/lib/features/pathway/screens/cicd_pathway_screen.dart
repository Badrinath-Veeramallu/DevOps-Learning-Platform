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
import '../data/cicd_curriculum_repository.dart';
import '../data/progress_service.dart';
import '../widgets/cicd_pathway_map.dart';
import '../widgets/pathway_fasttrack_banner.dart';
import '../widgets/pathway_header_card.dart';

/// Full CI/CD Learning Pathway Journey Screen matching Web's `CicdPathwayPage.jsx`.
class CicdPathwayScreen extends StatefulWidget {
  final List<CurriculumModule>? initialModules;
  final Set<String>? initialCompletedIds;

  const CicdPathwayScreen({
    super.key,
    this.initialModules,
    this.initialCompletedIds,
  });

  @override
  State<CicdPathwayScreen> createState() => _CicdPathwayScreenState();
}

class _CicdPathwayScreenState extends State<CicdPathwayScreen> {
  List<CurriculumModule> _modules = const [];
  Set<String> _completedIds = const {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cached = widget.initialModules ?? CicdCurriculumRepository.cachedModules;
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
        .getCompletedModules(userId, pathway: 'cicd')
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

    final cached = CicdCurriculumRepository.cachedModules;
    if (_modules.isEmpty && cached != null && cached.isNotEmpty) {
      setState(() {
        _modules = cached;
        _isLoading = false;
      });
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id ?? 'guest';

      final localCompleted = await ProgressService().getCompletedModules(userId, pathway: 'cicd');
      if (mounted && localCompleted.isNotEmpty && _completedIds.isEmpty) {
        setState(() => _completedIds = localCompleted);
      }

      final modules = await CicdCurriculumRepository.loadCurriculum();
      final completed = widget.initialCompletedIds ??
          await ProgressService()
              .fetchUserProgress(userId, pathway: 'cicd');

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
            _error = 'Failed to load CI/CD curriculum: $e';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _handleSelectModule(String moduleId) {
    if (!ProgressService.isModuleUnlocked(
      pathway: 'cicd',
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
    context.push('/pathways/cicd/$moduleId');
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
        ProgressService().isPathwayUnlocked(pathway: 'cicd', userId: userId);

    if (!isUnlocked) {
      final lockReason = ProgressService().getPathwayLockReason(
        pathway: 'cicd',
        userId: userId,
      );
      final isGitDone = ProgressService().isPathwayCompleted(pathway: 'git', userId: userId);
      final isLinuxDone = ProgressService().isPathwayCompleted(pathway: 'linux', userId: userId);
      final isDockerDone = ProgressService().isPathwayCompleted(pathway: 'docker', userId: userId);

      final targetRoute = !isGitDone
          ? RouteNames.gitPathway
          : (!isLinuxDone ? RouteNames.linuxPathway : (!isDockerDone ? RouteNames.dockerPathway : RouteNames.gitPathway));
      final targetLabel = !isGitDone
          ? 'Go to Git Pathway'
          : (!isLinuxDone ? 'Go to Linux Pathway' : (!isDockerDone ? 'Go to Docker Pathway' : 'Go to Git Pathway'));

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
                    'CI/CD & GitOps Delivery',
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
                      lockReason ?? 'Complete all prerequisite pathways to unlock CI/CD.',
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
                        onPressed: () => context.push(targetRoute),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: Text(targetLabel),
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
        currentIndex: 1,
        onTabSelected: _handleBottomNavTap,
      ),
      body: SafeArea(
        top: false,
        child: _isLoading && _modules.isEmpty
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
                          const SizedBox(height: 16),
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
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Pathway Hero Header Card
                        PathwayHeaderCard(
                          completedCount: _modules.where((m) => _completedIds.contains(m.id)).length,
                          totalCount: _modules.length,
                          modules: _modules,
                          completedIds: _completedIds,
                          onBack: _handleBackToDashboard,
                          title: 'CI/CD & GitOps Delivery Pathway',
                          description:
                              'A progressive, step-by-step interactive roadmap mastering automated build pipelines, Jenkins, GitHub Actions, testing automation, deployment strategies, and GitOps with Argo CD.',
                          badgeText: 'Intermediate Pathway',
                          allDoneText:
                              "🎉 You've completed all ${_modules.length} CI/CD stops!",
                        ),
                        if (_modules.where((m) => _completedIds.contains(m.id)).length < _modules.length)
                          PathwayFastTrackBanner(
                            pathwayTitle: 'CI/CD & GitOps Delivery',
                            onAttemptQuiz: () => context.push('/pathways/cicd/quiz?fastTrack=true'),
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
                        CicdPathwayMap(
                          modules: _modules,
                          completedModuleIds: _completedIds,
                          onSelectModule: _handleSelectModule,
                          onFinishTap: () =>
                              context.push('/pathways/cicd/quiz'),
                          finishText:
                              'CI/CD & GitOps Delivery Mastered!',
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
      ),
    );
  }
}
