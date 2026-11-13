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
import '../../pathway/data/activity_service.dart';
import '../../pathway/data/linux_curriculum_repository.dart';
import '../../pathway/data/progress_service.dart';
import '../../animations/services/animation_loader.dart';
import '../widgets/learning_content_renderer.dart';
import '../widgets/module_header_card.dart';
import '../widgets/module_objectives_card.dart';
import '../widgets/subtopic_nav_bar.dart';
import '../widgets/subtopic_nav_footer.dart';

/// Full feature and UI parity Linux Module Screen matching Web's `LinuxModulePage.jsx`.
///
/// Features:
/// - Dynamic module loading by ID
/// - Complete curriculum metadata and objectives
/// - Responsive subtopic navigation with ordered section switching
/// - Full educational content renderer with table support
/// - Module completion card support matching Web's `.module-completion-card`
/// - Module completion and pathway progress tracking isolated to Linux
class LinuxModuleScreen extends StatefulWidget {
  final String moduleId;
  final List<CurriculumModule>? initialModules;
  final Set<String>? initialCompletedIds;
  final int initialSubtopicIndex;

  const LinuxModuleScreen({
    super.key,
    required this.moduleId,
    this.initialModules,
    this.initialCompletedIds,
    this.initialSubtopicIndex = 0,
  });

  @override
  State<LinuxModuleScreen> createState() => _LinuxModuleScreenState();
}

class _LinuxModuleScreenState extends State<LinuxModuleScreen> {
  List<CurriculumModule> _modules = const [];
  CurriculumModule? _currentModule;
  int _selectedSubtopicIndex = 0;
  bool _isCompleted = false;
  bool _isLoading = true;
  String? _error;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedSubtopicIndex = widget.initialSubtopicIndex;
    final cached = widget.initialModules ?? LinuxCurriculumRepository.cachedModules;
    if (cached != null && cached.isNotEmpty) {
      _modules = cached;
      _resolveCurrentModule();
      _isLoading = false;
    }
    _loadData();
    ProgressService().addListener(_onProgressChanged);
  }

  @override
  void didUpdateWidget(covariant LinuxModuleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moduleId != widget.moduleId) {
      _resolveCurrentModule();
      _selectedSubtopicIndex = 0;
      _updateCompletionStatus();
      _logLessonViewed();
    }
  }

  @override
  void dispose() {
    ProgressService().removeListener(_onProgressChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) {
      _updateCompletionStatus();
    }
  }

  bool get _isLocked {
    if (_currentModule == null) return false;
    if (_currentModule!.order <= 1) return false;
    if (widget.initialModules != null && widget.initialCompletedIds == null) {
      return false;
    }
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    final completed =
        ProgressService().getCompletedModulesSync(userId, pathway: 'linux');
    final effectiveCompleted = completed.isNotEmpty
        ? completed
        : const <String>{};
    return !ProgressService.isModuleUnlocked(
      pathway: 'linux',
      moduleId: _currentModule!.id,
      completedModules: effectiveCompleted,
    );
  }

  void _checkLockAndRedirect() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    final isPathwayLocked = (widget.initialModules == null) &&
        !ProgressService().isPathwayUnlocked(pathway: 'linux', userId: userId);

    if ((isPathwayLocked || _isLocked) && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final msg = isPathwayLocked
              ? (ProgressService().getPathwayLockReason(pathway: 'linux', userId: userId) ??
                  'Linux pathway is locked.')
              : 'Complete the previous module to unlock this module.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              duration: const Duration(seconds: 2),
            ),
          );
          try {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.linuxPathway);
            }
          } catch (_) {}
        }
      });
    }
  }

  void _updateCompletionStatus() {
    if (_currentModule == null) return;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    final isDone = ProgressService().isModuleCompleted(
      userId,
      _currentModule!.id,
      pathway: 'linux',
    );
    setState(() => _isCompleted = isDone);
    _checkLockAndRedirect();
  }

  void _logLessonViewed() {
    if (_currentModule == null) return;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    ActivityService().logLessonViewed(
      userId: userId,
      stopSlug: _currentModule!.id,
      pathwayId: 'linux',
    );
  }

  void _handleAnimationFinish() {
    if (_currentModule == null) return;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    ActivityService().logAnimationFinished(
      userId: userId,
      stopSlug: _currentModule!.id,
      pathwayId: 'linux',
    );
  }

  Future<void> _loadData() async {
    // 1. Fast-path: Preload Linux animations independently and trigger UI refresh as soon as ready
    if (AnimationLoader.cachedModules(pathway: 'linux') == null) {
      AnimationLoader.loadAnimations(pathway: 'linux').then((_) {
        if (mounted) setState(() {});
      }).catchError((e) {
        debugPrint('[LinuxModuleScreen] Animation load error: $e');
      });
    }

    // 2. Handle passed initialModules
    if (widget.initialModules != null) {
      setState(() {
        _modules = widget.initialModules!;
        _resolveCurrentModule();
        _isLoading = false;
      });
      _updateCompletionStatus();
      _logLessonViewed();
      return;
    }

    // 3. Load curriculum if not yet loaded
    if (_modules.isEmpty) {
      try {
        final loadedModules = await LinuxCurriculumRepository.loadCurriculum();
        if (mounted) {
          setState(() {
            _modules = loadedModules;
            _resolveCurrentModule();
            _isLoading = false;
            _error = null;
          });
          _updateCompletionStatus();
          _logLessonViewed();
        }
      } catch (e) {
        if (mounted && _modules.isEmpty) {
          setState(() {
            _error = 'Failed to load Linux curriculum: $e';
            _isLoading = false;
          });
        }
      }
    } else {
      if (_isLoading && mounted) {
        setState(() => _isLoading = false);
      }
      _updateCompletionStatus();
      _logLessonViewed();
    }

    // 4. Background non-blocking progress sync
    if (!mounted) return;
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id ?? 'guest';
      await ProgressService().fetchUserProgress(userId, pathway: 'linux');
      if (mounted) {
        _updateCompletionStatus();
      }
    } catch (e) {
      debugPrint('[LinuxModuleScreen] Background progress sync error: $e');
    }
  }

  void _resolveCurrentModule() {
    if (_modules.isEmpty) return;
    final found = LinuxCurriculumRepository.findModule(_modules, widget.moduleId);
    _currentModule = found ?? _modules.first;

    final subtopicCount = _currentModule?.sections.length ?? 0;
    if (_selectedSubtopicIndex >= subtopicCount) {
      _selectedSubtopicIndex = 0;
    }
  }

  void _handleSubtopicSelected(int index) {
    setState(() {
      _selectedSubtopicIndex = index;
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        360,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleToggleComplete() async {
    if (_currentModule == null) return;
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the previous module to unlock this module.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';

    setState(() => _isCompleted = !_isCompleted);

    try {
      final res = await ProgressService().toggleModuleCompletion(
        userId,
        _currentModule!.id,
        pathway: 'linux',
        validateSequence: true,
        validatePathwayLock: widget.initialModules == null,
      );
      if (mounted) {
        setState(() => _isCompleted = res);
      }
    } catch (e) {
      if (mounted) {
        _updateCompletionStatus();
      }
    }
  }

  void _navigateToModule(CurriculumModule module) {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    final completed =
        ProgressService().getCompletedModulesSync(userId, pathway: 'linux');
    if (!ProgressService.isModuleUnlocked(
      pathway: 'linux',
      moduleId: module.id,
      completedModules: completed,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the previous module to unlock this module.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    context.pushReplacement('/pathways/linux/${module.id}');
  }

  void _handlePrevSubtopic() {
    if (_selectedSubtopicIndex > 0) {
      _handleSubtopicSelected(_selectedSubtopicIndex - 1);
    }
  }

  void _handleNextSubtopic() {
    final subtopicsCount = _currentModule?.sections.length ?? 0;
    if (_selectedSubtopicIndex < subtopicsCount - 1) {
      _handleSubtopicSelected(_selectedSubtopicIndex + 1);
    }
  }

  void _handleBackToPathway() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.linuxPathway);
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.lightAccent),
      );
    }

    if (_isLocked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 48, color: AppColors.textSubtle),
              const SizedBox(height: 16),
              Text(
                'Module Locked',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete the previous module to unlock this module.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleBackToPathway,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Return to Pathway'),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _currentModule == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Module not found: ${widget.moduleId}',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RouteNames.linuxPathway);
                  }
                },
                child: const Text('Back to Pathway'),
              ),
            ],
          ),
        ),
      );
    }

    final module = _currentModule!;
    final currentIndex = _modules.indexOf(module);
    final prevModule = currentIndex > 0 ? _modules[currentIndex - 1] : null;
    final nextModule =
        currentIndex < _modules.length - 1 ? _modules[currentIndex + 1] : null;

    final CurriculumSection? activeSection =
        module.sections.isNotEmpty && _selectedSubtopicIndex < module.sections.length
            ? module.sections[_selectedSubtopicIndex]
            : null;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Module Header Card
          ModuleHeaderCard(
            module: module,
            isCompleted: _isCompleted,
            totalStops: _modules.length,
            onBackToPathway: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteNames.linuxPathway);
              }
            },
          ),

          const SizedBox(height: 24),

          // Learning Objectives Card
          ModuleObjectivesCard(objectives: module.objectives),

          const SizedBox(height: 28),

          // Subtopic Navigation Bar (Tab pill list)
          SubtopicNavBar(
            sections: module.sections,
            selectedIndex: _selectedSubtopicIndex,
            onSelectSubtopic: _handleSubtopicSelected,
          ),

          const SizedBox(height: 16),

          // Educational Learning Content Section
          if (activeSection != null)
            LearningContentRenderer(
              key: ValueKey('linux-${module.id}-${activeSection.number}'),
              section: activeSection,
              moduleNumber: module.number,
              pathway: 'linux',
              onAnimationFinish: _handleAnimationFinish,
            ),

          // Module Completion Card (if present on module)
          if (module.moduleCompletion != null)
            _buildModuleCompletionCard(module.moduleCompletion!),

          const SizedBox(height: 28),

          // Subtopic Footer Navigation
          SubtopicNavFooter(
            currentSubtopicIndex: _selectedSubtopicIndex,
            totalSubtopics: module.sections.length,
            currentModule: module,
            prevModule: prevModule,
            nextModule: nextModule,
            isCompleted: _isCompleted,
            isNextLocked: nextModule != null && !_isCompleted,
            onPrevSubtopic: _handlePrevSubtopic,
            onNextSubtopic: _handleNextSubtopic,
            onToggleComplete: _handleToggleComplete,
            onNavigateModule: (id) {
              final target = LinuxCurriculumRepository.findModule(_modules, id);
              if (target != null) _navigateToModule(target);
            },
            onReturnToPathway: _handleBackToPathway,
            onTakeQuiz: () => context.push('/pathways/linux/quiz'),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildModuleCompletionCard(CurriculumModuleCompletion completion) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x1A10B981),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x5910B981),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x3310B981),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  completion.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: const Color(0xFFA7F3D0),
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...completion.paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                p,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMain,
                  height: 1.6,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
