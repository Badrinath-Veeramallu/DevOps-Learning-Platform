import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/app_header_bar.dart';
import '../../../models/quiz_model.dart';
import '../../../providers/auth_provider.dart';
import '../data/quiz_service.dart';
import '../../pathway/data/progress_service.dart';

/// Interactive Final Quiz Screen for Git, Docker, Linux, and CI/CD pathways.
/// Supports both standard pathway completion quizzes and fast-track assessments.
class PathwayQuizScreen extends StatefulWidget {
  final String pathwayId;
  final bool isFastTrack;
  final bool autoStart;

  const PathwayQuizScreen({
    super.key,
    required this.pathwayId,
    this.isFastTrack = false,
    this.autoStart = false,
  });

  @override
  State<PathwayQuizScreen> createState() => _PathwayQuizScreenState();
}

class _PathwayQuizScreenState extends State<PathwayQuizScreen> {
  final QuizService _quizService = QuizService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String? _error;
  String? _prereqError;

  List<QuizQuestion> _questions = const [];
  QuizStatus? _quizStatus;
  int _currentIndex = 0;
  final Map<String, int> _answers = {};

  bool _hasStarted = false;
  bool _isSubmitting = false;
  QuizResult? _result;
  bool _showReview = false;

  String get _pathwayTitle {
    switch (widget.pathwayId.toLowerCase()) {
      case 'git':
        return 'Git & GitHub';
      case 'docker':
        return 'Docker & Containers';
      case 'linux':
        return 'Linux Essentials';
      case 'cicd':
        return 'CI/CD & GitOps Delivery';
      default:
        return widget.pathwayId.toUpperCase();
    }
  }

  @override
  void initState() {
    super.initState();
    _hasStarted = widget.autoStart;
    _loadQuiz();
  }

  @override
  void didUpdateWidget(covariant PathwayQuizScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pathwayId != widget.pathwayId ||
        oldWidget.isFastTrack != widget.isFastTrack) {
      _hasStarted = widget.autoStart;
      _loadQuiz();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _prereqError = null;
      _result = null;
      _answers.clear();
      _currentIndex = 0;
    });

    try {
      final res = widget.isFastTrack
          ? await _quizService.fetchFastTrackQuiz(widget.pathwayId)
          : await _quizService.fetchQuiz(widget.pathwayId);
      if (mounted) {
        setState(() {
          _questions = res.questions;
          _quizStatus = res.status;
          _isLoading = false;
        });
      }
    } on QuizPrerequisiteException catch (e) {
      if (mounted) {
        setState(() {
          _prereqError = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load quiz: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _selectOption(int optionIndex) {
    if (_questions.isEmpty) return;
    final currentQ = _questions[_currentIndex];
    setState(() {
      _answers[currentQ.id] = optionIndex;
    });
  }

  void _handleNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
      _scrollToTop();
    } else {
      _showSubmitConfirmation();
    }
  }

  void _handlePrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _showSubmitConfirmation() {
    final answeredCount = _answers.length;
    final total = _questions.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Submit Final Quiz?',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You have answered $answeredCount of $total questions.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              if (answeredCount < total)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Warning: You still have ${total - answeredCount} unanswered questions!',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.borderDefault),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Review'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _submitQuiz();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Submit Quiz'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitQuiz() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? 'guest';

    setState(() => _isSubmitting = true);
    try {
      final res = widget.isFastTrack
          ? await _quizService.submitFastTrackQuiz(
              pathwayId: widget.pathwayId,
              answers: _answers,
            )
          : await _quizService.submitQuiz(
              pathwayId: widget.pathwayId,
              answers: _answers,
            );

      if (res.passed) {
        if (widget.isFastTrack && res.completedModules.isNotEmpty) {
          ProgressService().setCompletedModulesCache(
            userId,
            res.completedModules.toSet(),
            pathway: widget.pathwayId,
            synced: true,
          );
        }
        try {
          await ProgressService().fetchAllPathwaysStatus(userId);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _result = res;
          _isSubmitting = false;
        });
        _scrollToTop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit quiz: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleRetake() {
    setState(() {
      _result = null;
      _answers.clear();
      _currentIndex = 0;
      _showReview = false;
    });
    _scrollToTop();
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
      body: _buildBody(),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onTabSelected: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading || _isSubmitting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            if (_isSubmitting) ...[
              const SizedBox(height: 16),
              Text(
                'Evaluating quiz answers...',
                style: AppTypography.bodyMedium,
              ),
            ],
          ],
        ),
      );
    }

    if (_prereqError != null) {
      return _buildPrereqLockedView();
    }

    if (_error != null || _questions.isEmpty) {
      return _buildErrorView();
    }

    if (_result != null) {
      return _buildResultView();
    }

    if (!_hasStarted) {
      return _buildQuizIntroView();
    }

    return _buildQuizActiveView();
  }

  Widget _buildPrereqLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFEF3C7),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFB45309),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Final Quiz Locked',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _prereqError ??
                  'You must complete all modules in this pathway before attempting the final quiz.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go('/pathways/${widget.pathwayId}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Return to Pathway'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unable to load quiz',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(color: AppColors.textMain),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizIntroView() {
    final total = _questions.length;
    final passingCount = (_questions.length * 0.5).round();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Exit Quiz Link
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/pathways/${widget.pathwayId}');
                }
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Exit Quiz'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Introduction Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.primaryBorder),
                      ),
                      child: Text(
                        _pathwayTitle.toUpperCase(),
                        style: AppTypography.badgeText.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_quizStatus?.hasPassed == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Text(
                          '✓ Previously Passed',
                          style: TextStyle(
                            color: Color(0xFF15803D),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isFastTrack ? 'Pathway Assessment' : 'Final Comprehensive Quiz',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isFastTrack
                      ? 'Demonstrate your existing knowledge of $_pathwayTitle. Score 10/20 (50%) or higher to pass and skip to the next pathway!'
                      : 'Test your complete knowledge across all lessons. Score 10/20 (50%) or higher to officially record your mastery!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),

                // Key metrics row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.format_list_numbered_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(height: 6),
                            Text(
                              '$total Questions',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Multiple Choice',
                              style: TextStyle(color: AppColors.textSubtle, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                            const SizedBox(height: 6),
                            Text(
                              '$passingCount / $total (50%)',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Passing Criteria',
                              style: TextStyle(color: AppColors.textSubtle, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Guidelines
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8DDE0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions & Rules',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint('Answer each question one by one or navigate freely using question pills.'),
                      _buildBulletPoint('Score 10/20 (50%) or higher to pass.'),
                      _buildBulletPoint('You may retake the quiz anytime with unlimited attempts.'),
                      _buildBulletPoint('Detailed answers and explanations are available upon submission.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Start Quiz Button
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _hasStarted = true);
                    _scrollToTop();
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text(
                    'Start Quiz',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizActiveView() {
    final currentQ = _questions[_currentIndex];
    final selectedOption = _answers[currentQ.id];
    final total = _questions.length;
    final progressPercent = (_currentIndex + 1) / total;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Nav: Exit Quiz Link & Answered Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/pathways/${widget.pathwayId}');
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Exit Quiz'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                ),
              ),
              Text(
                'Answered: ${_answers.length}/$total',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Header Card with Pathway Badge & Progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.primaryBorder),
                          ),
                          child: Text(
                            _pathwayTitle.toUpperCase(),
                            style: AppTypography.badgeText.copyWith(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_quizStatus?.hasPassed == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Text(
                              'PASSED',
                              style: TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Answered: ${_answers.length}/$total',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isFastTrack ? 'Pathway Assessment' : 'Final Comprehensive Quiz',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isFastTrack
                      ? 'Demonstrate your existing knowledge of $_pathwayTitle. Score 10/20 (50%) or higher to pass and skip to the next pathway!'
                      : 'Passing score: 10/20 (50%). Unlimited retakes.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF5ECEF),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Question Navigation Pill Selector (1..20)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: total,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final qId = _questions[idx].id;
                final isAnswered = _answers.containsKey(qId);
                final isActive = idx == _currentIndex;

                return InkWell(
                  onTap: () {
                    setState(() => _currentIndex = idx);
                    _scrollToTop();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : (isAnswered ? const Color(0xFFFCF8F9) : AppColors.surface),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary
                            : (isAnswered ? AppColors.accent : AppColors.borderDefault),
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '${idx + 1}',
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : (isAnswered ? AppColors.primary : AppColors.textMuted),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 3. Question Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDefault),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'QUESTION ${_currentIndex + 1} OF $total',
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.accent,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  currentQ.question,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),

                // 4 Options
                ...List.generate(currentQ.options.length, (optIdx) {
                  final optText = currentQ.options[optIdx];
                  final isSelected = selectedOption == optIdx;
                  final optLetter = String.fromCharCode(65 + optIdx); // A, B, C, D

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _selectOption(optIdx),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFCF4F6)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderDefault,
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFF5ECEF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                optLetter,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                optText,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textMain,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Controls Bar (Prev / Submit / Next)
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _currentIndex > 0 ? _handlePrev : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Prev'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.borderDefault),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _showSubmitConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Submit'),
              ),
              if (_currentIndex < total - 1) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _handleNext,
                  label: const Text('Next'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final res = _result!;
    final isPass = res.passed;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Nav: Return to Pathway Map Link
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.go('/pathways/${widget.pathwayId}'),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Return to Pathway Map'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Hero Result Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderDefault),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPass ? AppColors.successBg : AppColors.errorBg,
                  ),
                  child: Center(
                    child: Text(
                      isPass ? '🏆' : '📝',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isPass ? 'Congratulations! You Passed!' : 'Keep Practicing!',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: isPass ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),

                // Score Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${res.score} / ${res.totalQuestions}',
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${res.percentage}% Score (Passing: 10/20)',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Builder(builder: (context) {
                  const nextPathwayLabels = {
                    'git': 'Linux Essentials',
                    'linux': 'Docker & Containers',
                    'docker': 'CI/CD & GitOps Delivery',
                    'cicd': 'Kubernetes Cluster Architecture',
                  };
                  final nextLabel = nextPathwayLabels[widget.pathwayId.toLowerCase()];
                  final passText = widget.isFastTrack
                      ? 'Outstanding! You have demonstrated prior mastery of $_pathwayTitle. All stops have been marked complete${nextLabel != null ? " and $nextLabel is now unlocked!" : "."}'
                      : 'You have demonstrated mastery of $_pathwayTitle. Your final quiz completion is officially recorded!';

                  return Text(
                    isPass
                        ? passText
                        : 'You scored ${res.score} out of ${res.totalQuestions}. A score of at least 10 (50%) is required to pass. You can retake the quiz anytime!',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
                  );
                }),

                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _showReview = !_showReview);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.borderDefault),
                      ),
                      child: Text(_showReview ? 'Hide Review' : 'Review Answers'),
                    ),
                    ElevatedButton(
                      onPressed: _handleRetake,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retake Quiz'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.go('/pathways/${widget.pathwayId}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primaryBorder),
                      ),
                      child: const Text('Back to Pathway'),
                    ),
                    if (isPass)
                      Builder(builder: (context) {
                        const nextPathways = {
                          'git': 'linux',
                          'linux': 'docker',
                          'docker': 'cicd',
                          'cicd': 'kubernetes',
                        };
                        const nextPathwayLabels = {
                          'git': 'Linux Essentials',
                          'linux': 'Docker & Containers',
                          'docker': 'CI/CD & GitOps Delivery',
                          'cicd': 'Kubernetes Cluster Architecture',
                        };
                        final nextId = nextPathways[widget.pathwayId.toLowerCase()];
                        final nextLabel = nextPathwayLabels[widget.pathwayId.toLowerCase()];
                        if (nextId == null || nextLabel == null || nextId == 'kubernetes') {
                          return const SizedBox.shrink();
                        }
                        return ElevatedButton(
                          onPressed: () {
                            context.go('/pathways/$nextId');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Continue to $nextLabel →'),
                        );
                      }),
                  ],
                ),
              ],
            ),
          ),

          // Review Section
          if (_showReview) ...[
            const SizedBox(height: 24),
            Text(
              'Detailed Answer Review',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...res.review.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.isCorrect ? AppColors.success : AppColors.error,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.id.toUpperCase(),
                          style: AppTypography.badgeText.copyWith(
                            color: AppColors.textSubtle,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.isCorrect
                                ? AppColors.successBg
                                : AppColors.errorBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.isCorrect ? '✓ Correct' : '✕ Incorrect',
                            style: TextStyle(
                              color: item.isCorrect
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.question,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(item.options.length, (optIdx) {
                      final opt = item.options[optIdx];
                      final isCorrect = optIdx == item.correctOption;
                      final isUser = optIdx == item.selectedOption;

                      Color itemBorder = AppColors.borderDefault;
                      Color itemBg = Colors.white;
                      if (isCorrect) {
                        itemBorder = AppColors.success;
                        itemBg = AppColors.successBg;
                      } else if (isUser && !item.isCorrect) {
                        itemBorder = AppColors.error;
                        itemBg = AppColors.errorBg;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: itemBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: itemBorder),
                        ),
                        child: Row(
                          children: [
                            Text(
                              String.fromCharCode(65 + optIdx),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isCorrect ? AppColors.success : AppColors.textMain,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(opt, style: const TextStyle(fontSize: 13))),
                            if (isCorrect)
                              const Text(
                                '(Correct)',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            if (isUser && !isCorrect)
                              const Text(
                                '(Your Answer)',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    if (item.explanation != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Explanation: ${item.explanation}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
