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
import '../../pathway/data/git_curriculum_repository.dart';
import '../../pathway/data/progress_service.dart';
import '../widgets/learning_content_renderer.dart';
import '../widgets/module_header_card.dart';
import '../widgets/module_objectives_card.dart';
import '../widgets/subtopic_nav_bar.dart';
import '../widgets/subtopic_nav_footer.dart';

/// Full feature and UI parity Git Module Screen matching Web's `GitModulePage.jsx`.
///
/// Features:
/// - Dynamic module loading by ID
/// - Complete curriculum metadata and objectives
/// - Responsive subtopic navigation with ordered section switching
/// - Full educational content renderer (headings, code blocks, lists, animations)
/// - Module completion and pathway progress tracking
class GitModuleScreen extends StatefulWidget {
  final String moduleId;
  final List<CurriculumModule>? initialModules;
  final Set<String>? initialCompletedIds;
  final int initialSubtopicIndex;

  const GitModuleScreen({
    super.key,
    required this.moduleId,
    this.initialModules,
    this.initialCompletedIds,
    this.initialSubtopicIndex = 0,
  });

  @override
  State<GitModuleScreen> createState() => _GitModuleScreenState();
}

class _GitModuleScreenState extends State<GitModuleScreen> {
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
    _loadData();
    ProgressService().addListener(_onProgressChanged);
  }

  @override
  void didUpdateWidget(covariant GitModuleScreen oldWidget) {
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

  void _updateCompletionStatus() {
    if (_currentModule == null) return;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    final isDone = ProgressService().isModuleCompleted(userId, _currentModule!.id);
    setState(() => _isCompleted = isDone);
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

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id ?? 'guest';

      // Load curriculum and animations in parallel, syncing user progress
      final results = await Future.wait([
        GitCurriculumRepository.loadCurriculum(),
        AnimationLoader.loadAnimations(),
        ProgressService().fetchUserProgress(userId),
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
          _error = 'Failed to load module content: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _resolveCurrentModule() {
    if (_modules.isEmpty) return;
    final found = GitCurriculumRepository.findModule(_modules, widget.moduleId);
    _currentModule = found ?? _modules.first;
  }

  void _handleBackToPathway() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.gitPathway);
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

    final isNowDone = await ProgressService().toggleModuleCompletion(
      userId,
      _currentModule!.id,
    );

    if (mounted) {
      setState(() => _isCompleted = isNowDone);
      final isSynced = ProgressService().isSynced(userId);
      final syncSuffix = isSynced ? '' : ' (Saved locally)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowDone
                ? 'Module ${_currentModule!.order} marked as completed!$syncSuffix'
                : 'Module ${_currentModule!.order} marked as incomplete.$syncSuffix',
          ),
          backgroundColor: isNowDone ? AppColors.success : AppColors.surfaceElevated,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleNavigateModule(String targetModuleId) {
    context.push('/pathways/git/$targetModuleId');
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.dashboard);
        break;
      case 1:
        context.go(RouteNames.gitPathway);
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.lightAccent),
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
            onPrevSubtopic: _handlePrevSubtopic,
            onNextSubtopic: _handleNextSubtopic,
            onToggleComplete: _handleToggleComplete,
            onNavigateModule: _handleNavigateModule,
            onReturnToPathway: _handleBackToPathway,
          ),
        ],
      ),
    );
  }
}

