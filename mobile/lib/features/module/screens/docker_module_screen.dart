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
import '../../pathway/data/activity_service.dart';
import '../../pathway/data/docker_curriculum_repository.dart';
import '../../pathway/data/progress_service.dart';
import '../widgets/learning_content_renderer.dart';
import '../widgets/module_header_card.dart';
import '../widgets/module_objectives_card.dart';
import '../widgets/subtopic_nav_bar.dart';
import '../widgets/subtopic_nav_footer.dart';

/// Full feature and UI parity Docker Module Screen matching Web's `DockerModulePage.jsx`.
///
/// Features:
/// - Dynamic module loading by ID
/// - Complete curriculum metadata and objectives
/// - Responsive subtopic navigation with ordered section switching
/// - Full educational content renderer with Docker animations
/// - Module completion and pathway progress tracking isolated to Docker
class DockerModuleScreen extends StatefulWidget {
  final String moduleId;
  final List<CurriculumModule>? initialModules;
  final Set<String>? initialCompletedIds;
  final int initialSubtopicIndex;

  const DockerModuleScreen({
    super.key,
    required this.moduleId,
    this.initialModules,
    this.initialCompletedIds,
    this.initialSubtopicIndex = 0,
  });

  @override
  State<DockerModuleScreen> createState() => _DockerModuleScreenState();
}

class _DockerModuleScreenState extends State<DockerModuleScreen> {
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
    final cached = widget.initialModules ?? DockerCurriculumRepository.cachedModules;
    if (cached != null && cached.isNotEmpty) {
      _modules = cached;
      _resolveCurrentModule();
      _isLoading = false;
    }
    _loadData();
    ProgressService().addListener(_onProgressChanged);
  }

  @override
  void didUpdateWidget(covariant DockerModuleScreen oldWidget) {
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
        ProgressService().getCompletedModulesSync(userId, pathway: 'docker');
    final effectiveCompleted = completed.isNotEmpty
        ? completed
        : (widget.initialCompletedIds ?? const {});
    return !ProgressService.isModuleUnlocked(
      pathway: 'docker',
      moduleId: _currentModule!.id,
      completedModules: effectiveCompleted,
    );
  }

  void _checkLockAndRedirect() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    final isPathwayLocked = (widget.initialModules == null) &&
        !ProgressService().isPathwayUnlocked(pathway: 'docker', userId: userId);

    if ((isPathwayLocked || _isLocked) && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final msg = isPathwayLocked
              ? (ProgressService().getPathwayLockReason(pathway: 'docker', userId: userId) ??
                  'Docker pathway is locked.')
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
              context.go(RouteNames.dockerPathway);
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
      pathway: 'docker',
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
    );
  }

  void _handleAnimationFinish() {
    if (_currentModule == null) return;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    ActivityService().logAnimationFinished(
      userId: userId,
      stopSlug: _currentModule!.id,
    );
  }

  Future<void> _loadData() async {
    if (widget.initialModules != null) {
      _modules = widget.initialModules!;
      _resolveCurrentModule();
      if (widget.initialCompletedIds != null && _currentModule != null) {
        _isCompleted = widget.initialCompletedIds!.contains(_currentModule!.id);
      }
      setState(() => _isLoading = false);
      _logLessonViewed();
      return;
    }

    final cached = DockerCurriculumRepository.cachedModules;
    if (_modules.isEmpty && cached != null && cached.isNotEmpty) {
      _modules = cached;
      _resolveCurrentModule();
      setState(() => _isLoading = false);
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id ?? 'guest';

      // Load curriculum and animations in parallel, syncing user progress
      final results = await Future.wait([
        DockerCurriculumRepository.loadCurriculum(),
        AnimationLoader.loadAnimations(pathway: 'docker'),
        ProgressService().fetchUserProgress(userId, pathway: 'docker'),
      ]);

      final loadedModules = results[0] as List<CurriculumModule>;
      final completed = results[2] as Set<String>;

      if (mounted) {
        setState(() {
          _modules = loadedModules;
          _resolveCurrentModule();
          if (_currentModule != null) {
            _isCompleted = completed.contains(_currentModule!.id);
          }
          _isLoading = false;
        });
        _logLessonViewed();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load Docker module content: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _resolveCurrentModule() {
    if (_modules.isEmpty) return;
    final found = DockerCurriculumRepository.findModule(_modules, widget.moduleId);
    _currentModule = found ?? _modules.first;
  }

  void _handleBackToPathway() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.dockerPathway);
    }
  }

  void _handleSelectSubtopic(int index) {
    setState(() => _selectedSubtopicIndex = index);
    // Smooth scroll down to subtopic content area if user was further down
    _scrollController.animateTo(
      180,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _handlePrevSubtopic() {
    if (_selectedSubtopicIndex > 0) {
      _handleSelectSubtopic(_selectedSubtopicIndex - 1);
    }
  }

  void _handleNextSubtopic() {
    if (_currentModule != null &&
        _selectedSubtopicIndex < _currentModule!.sections.length - 1) {
      _handleSelectSubtopic(_selectedSubtopicIndex + 1);
    }
  }

  Future<void> _handleToggleComplete() async {
    if (_currentModule == null) return;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';

    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the previous module to unlock this module.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final isNowDone = await ProgressService().toggleModuleCompletion(
      userId,
      _currentModule!.id,
      pathway: 'docker',
      validateSequence: true,
      validatePathwayLock: widget.initialModules == null,
    );

    if (mounted) {
      setState(() => _isCompleted = isNowDone);
      final isSynced = ProgressService().isSynced(userId, pathway: 'docker');
      final syncSuffix = isSynced ? '' : ' (Saved locally)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowDone
                ? 'Module ${_currentModule!.order} marked as completed!$syncSuffix'
                : 'Module ${_currentModule!.order} marked as incomplete.$syncSuffix',
          ),
          backgroundColor: isNowDone ? AppColors.success : AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleNavigateModule(String targetModuleId) {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    final completed =
        ProgressService().getCompletedModulesSync(userId, pathway: 'docker');
    if (!ProgressService.isModuleUnlocked(
      pathway: 'docker',
      moduleId: targetModuleId,
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
    context.push('/pathways/docker/$targetModuleId');
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
        currentIndex: 0,
        onTabSelected: _handleBottomNavTap,
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _isLocked
                ? Center(
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
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _error = null;
                              });
                              _loadData();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _currentModule == null
                    ? const Center(child: Text('Module not found'))
                    : _buildModuleContent(),
      ),
    );
  }

  Widget _buildModuleContent() {
    final module = _currentModule!;
    final sections = module.sections;
    final int validSubtopicIndex = _selectedSubtopicIndex.clamp(
      0,
      sections.isNotEmpty ? sections.length - 1 : 0,
    );
    final currentSection =
        sections.isNotEmpty ? sections[validSubtopicIndex] : null;

    final moduleIndex = _modules.indexOf(module);
    final prevModule = moduleIndex > 0 ? _modules[moduleIndex - 1] : null;
    final nextModule =
        moduleIndex < _modules.length - 1 ? _modules[moduleIndex + 1] : null;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Module Header & Metadata Card
          ModuleHeaderCard(
            module: module,
            isCompleted: _isCompleted,
            onBackToPathway: _handleBackToPathway,
          ),

          // 2. Learning Objectives Box
          ModuleObjectivesCard(objectives: module.objectives),

          // 3. Subtopic Selector Pills
          if (sections.isNotEmpty)
            SubtopicNavBar(
              sections: sections,
              selectedIndex: validSubtopicIndex,
              onSelectSubtopic: _handleSelectSubtopic,
            ),

          // 4. Active Subtopic Content Renderer
          if (currentSection != null)
            LearningContentRenderer(
              section: currentSection,
              moduleNumber: module.number,
              pathway: 'docker',
              onAnimationFinish: _handleAnimationFinish,
            ),

          // 5. Navigation & Completion Footer
          SubtopicNavFooter(
            currentSubtopicIndex: validSubtopicIndex,
            totalSubtopics: sections.length,
            currentModule: module,
            prevModule: prevModule,
            nextModule: nextModule,
            isCompleted: _isCompleted,
            isNextLocked: nextModule != null && !_isCompleted,
            onPrevSubtopic: _handlePrevSubtopic,
            onNextSubtopic: _handleNextSubtopic,
            onToggleComplete: _handleToggleComplete,
            onNavigateModule: _handleNavigateModule,
            onReturnToPathway: _handleBackToPathway,
            onTakeQuiz: () => context.push('/pathways/docker/quiz'),
          ),
        ],
      ),
    );
  }
}

