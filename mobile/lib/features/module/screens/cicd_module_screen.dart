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
import '../../pathway/data/cicd_curriculum_repository.dart';
import '../../pathway/data/progress_service.dart';
import '../widgets/learning_content_renderer.dart';
import '../widgets/module_header_card.dart';
import '../widgets/module_objectives_card.dart';
import '../widgets/subtopic_nav_bar.dart';
import '../widgets/subtopic_nav_footer.dart';

/// Full feature and UI parity CI/CD Module Screen matching Web's `CicdModulePage.jsx`.
class CicdModuleScreen extends StatefulWidget {
  final String moduleId;
  final List<CurriculumModule>? initialModules;
  final Set<String>? initialCompletedIds;
  final int initialSubtopicIndex;

  const CicdModuleScreen({
    super.key,
    required this.moduleId,
    this.initialModules,
    this.initialCompletedIds,
    this.initialSubtopicIndex = 0,
  });

  @override
  State<CicdModuleScreen> createState() => _CicdModuleScreenState();
}

class _CicdModuleScreenState extends State<CicdModuleScreen> {
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
    final cached = widget.initialModules ?? CicdCurriculumRepository.cachedModules;
    if (cached != null && cached.isNotEmpty) {
      _modules = cached;
      _resolveCurrentModule();
      _isLoading = false;
    }
    _loadData();
    ProgressService().addListener(_onProgressChanged);
  }

  @override
  void didUpdateWidget(covariant CicdModuleScreen oldWidget) {
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
        ProgressService().getCompletedModulesSync(userId, pathway: 'cicd');
    final effectiveCompleted = completed.isNotEmpty
        ? completed
        : (widget.initialCompletedIds ?? const {});
    return !ProgressService.isModuleUnlocked(
      pathway: 'cicd',
      moduleId: _currentModule!.id,
      completedModules: effectiveCompleted,
    );
  }

  void _checkLockAndRedirect() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';
    final isPathwayLocked = (widget.initialModules == null) &&
        !ProgressService().isPathwayUnlocked(pathway: 'cicd', userId: userId);

    if ((isPathwayLocked || _isLocked) && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final msg = isPathwayLocked
              ? (ProgressService().getPathwayLockReason(pathway: 'cicd', userId: userId) ??
                  'CI/CD pathway is locked.')
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
              context.go(RouteNames.cicdPathway);
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
      pathway: 'cicd',
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
      pathwayId: 'cicd',
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

      final results = await Future.wait([
        CicdCurriculumRepository.loadCurriculum(),
        ProgressService().fetchUserProgress(userId, pathway: 'cicd'),
      ]);

      final loadedModules = results[0] as List<CurriculumModule>;
      final completed = results[1] as Set<String>;

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
          _error = 'Failed to load CI/CD module content: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _resolveCurrentModule() {
    if (_modules.isEmpty) return;
    final found = CicdCurriculumRepository.findModule(_modules, widget.moduleId);
    _currentModule = found ?? _modules.first;
  }

  void _handleBackToPathway() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.cicdPathway);
    }
  }

  void _handleSelectSubtopic(int index) {
    setState(() => _selectedSubtopicIndex = index);
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
      pathway: 'cicd',
      validateSequence: true,
      validatePathwayLock: widget.initialModules == null,
    );

    if (mounted) {
      setState(() => _isCompleted = isNowDone);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowDone
                ? 'Module ${_currentModule!.order} marked as completed!'
                : 'Module ${_currentModule!.order} marked as incomplete.',
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
        ProgressService().getCompletedModulesSync(userId, pathway: 'cicd');
    if (!ProgressService.isModuleUnlocked(
      pathway: 'cicd',
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
    context.push('/pathways/cicd/$targetModuleId');
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
                    : SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Back to Pathway Button
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _handleBackToPathway,
                                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                label: const Text('Back to CI/CD Pathway'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 2. Module Header Card
                            ModuleHeaderCard(
                              module: _currentModule!,
                              isCompleted: _isCompleted,
                              onBackToPathway: _handleBackToPathway,
                            ),
                            const SizedBox(height: 16),

                            // 3. Module Learning Objectives
                            ModuleObjectivesCard(
                              objectives: _currentModule!.objectives,
                            ),
                            const SizedBox(height: 20),

                            // 4. Subtopic Navigation Bar
                            if (_currentModule!.sections.isNotEmpty)
                              SubtopicNavBar(
                                sections: _currentModule!.sections,
                                selectedIndex: _selectedSubtopicIndex,
                                onSelectSubtopic: _handleSelectSubtopic,
                              ),
                            const SizedBox(height: 16),

                            // 5. Active Subtopic Educational Content Renderer with animation placeholder spacing
                            if (_currentModule!.sections.isNotEmpty)
                              LearningContentRenderer(
                                section: _currentModule!.sections[_selectedSubtopicIndex],
                                moduleNumber: _currentModule!.number,
                                pathway: 'cicd',
                              ),
                            const SizedBox(height: 24),

                            // 6. Navigation Footer (Prev/Next subtopic, Toggle complete, Next module navigation, Quiz CTA)
                            Builder(
                              builder: (context) {
                                final currentIdx = _modules.indexOf(_currentModule!);
                                final prevMod = currentIdx > 0 ? _modules[currentIdx - 1] : null;
                                final nextMod = currentIdx < _modules.length - 1
                                    ? _modules[currentIdx + 1]
                                    : null;
                                final isNextLocked = nextMod != null && !_isCompleted;

                                return SubtopicNavFooter(
                                  currentSubtopicIndex: _selectedSubtopicIndex,
                                  totalSubtopics: _currentModule!.sections.length,
                                  currentModule: _currentModule!,
                                  prevModule: prevMod,
                                  nextModule: nextMod,
                                  isCompleted: _isCompleted,
                                  isNextLocked: isNextLocked,
                                  onPrevSubtopic: _handlePrevSubtopic,
                                  onNextSubtopic: _handleNextSubtopic,
                                  onToggleComplete: _handleToggleComplete,
                                  onNavigateModule: _handleNavigateModule,
                                  onReturnToPathway: _handleBackToPathway,
                                  onTakeQuiz: () => context.push('/pathways/cicd/quiz'),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}
