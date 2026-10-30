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
import '../data/git_curriculum_repository.dart';
import '../data/progress_service.dart';
import '../widgets/git_pathway_map.dart';
import '../widgets/pathway_header_card.dart';

/// Full Git Learning Pathway Journey Screen matching Web's `GitPathwayPage.jsx`.
///
/// Features:
/// - Hero Header Card with completion meter & next-stop hints
/// - Learning Journey section header
/// - Winding S-shaped 7-stop roadmap
/// - Responsive adaptation for mobile phones
/// - Navigation to `/pathways/git/:moduleId`
class GitPathwayScreen extends StatefulWidget {
  final List<CurriculumModule>? initialModules;
  final Set<String>? initialCompletedIds;

  const GitPathwayScreen({
    super.key,
    this.initialModules,
    this.initialCompletedIds,
  });

  @override
  State<GitPathwayScreen> createState() => _GitPathwayScreenState();
}

class _GitPathwayScreenState extends State<GitPathwayScreen> {
  List<CurriculumModule> _modules = const [];
  Set<String> _completedIds = const {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
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
    ProgressService().getCompletedModules(userId).then((completed) {
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

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id ?? 'guest';
      final modules = await GitCurriculumRepository.loadCurriculum();
      final completed = widget.initialCompletedIds ??
          await ProgressService().fetchUserProgress(userId);

      if (mounted) {
        setState(() {
          _modules = modules;
          _completedIds = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load Git curriculum: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _handleSelectModule(String moduleId) {
    context.push('/pathways/git/$moduleId');
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
        // Already on Git Pathway
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
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
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
                          completedCount: _completedIds.length,
                          totalCount: _modules.length,
                          modules: _modules,
                          completedIds: _completedIds,
                          onBack: _handleBackToDashboard,
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
                        GitPathwayMap(
                          modules: _modules,
                          completedModuleIds: _completedIds,
                          onSelectModule: _handleSelectModule,
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
      ),
    );
  }
}
