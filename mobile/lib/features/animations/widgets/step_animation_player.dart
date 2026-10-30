import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/animation_model.dart';
import '../services/step_engine.dart';
import 'animation_controls.dart';
import 'stage_canvas.dart';
import 'terminal_view.dart';

/// Full interactive Git Animation Player matching Web's `StepAnimation.jsx`.
///
/// Features:
/// - Exact state frames compiled by [StepEngine.buildFrames]
/// - Automatic and manual step progression
/// - Terminal command and execution state log
/// - Current step explanation and context
/// - Completion telemetry firing exactly once upon final step
class StepAnimationPlayer extends StatefulWidget {
  final SubtopicAnimation animation;
  final bool autoPlay;
  final int stepMs;
  final VoidCallback? onFinish;

  const StepAnimationPlayer({
    super.key,
    required this.animation,
    this.autoPlay = false,
    this.stepMs = 3200,
    this.onFinish,
  });

  @override
  State<StepAnimationPlayer> createState() => _StepAnimationPlayerState();
}

class _StepAnimationPlayerState extends State<StepAnimationPlayer> {
  late List<AnimationFrame> _frames;
  int _currentStep = 0;
  bool _isPlaying = false;
  bool _finishedFired = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initFrames();
    if (widget.autoPlay && _frames.length > 1) {
      _startPlayback();
    }
  }

  @override
  void didUpdateWidget(covariant StepAnimationPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation.id != widget.animation.id) {
      _stopPlayback();
      _initFrames();
      _currentStep = 0;
      _finishedFired = false;
      if (widget.autoPlay && _frames.length > 1) {
        _startPlayback();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _initFrames() {
    _frames = StepEngine.buildFrames(widget.animation.steps);
    if (_frames.isEmpty) {
      _frames = [
        const AnimationFrame(
          actors: {},
          edges: [],
          term: [],
          termStart: 0,
          say: '',
        ),
      ];
    }
  }

  void _startPlayback() {
    _stopPlayback();
    setState(() => _isPlaying = true);
    _scheduleNextStep();
  }

  void _stopPlayback() {
    _timer?.cancel();
    _timer = null;
    if (_isPlaying && mounted) {
      setState(() => _isPlaying = false);
    } else {
      _isPlaying = false;
    }
  }

  void _scheduleNextStep() {
    _timer?.cancel();
    final int last = _frames.length - 1;
    if (_currentStep >= last) {
      _stopPlayback();
      _checkCompletion();
      return;
    }

    final nextFrame = _frames[_currentStep + 1];
    final int typingDelay =
        (nextFrame.term.length - nextFrame.termStart) * 350;
    final int delay = widget.stepMs + typingDelay;

    _timer = Timer(Duration(milliseconds: delay), () {
      if (!mounted || !_isPlaying) return;
      setState(() {
        _currentStep++;
      });
      _checkCompletion();
      if (_currentStep < last) {
        _scheduleNextStep();
      } else {
        _stopPlayback();
      }
    });
  }

  void _checkCompletion() {
    final int last = _frames.length - 1;
    if (_currentStep >= last && last > 0 && !_finishedFired) {
      _finishedFired = true;
      widget.onFinish?.call();
    }
  }

  void _goToStep(int stepIndex) {
    _stopPlayback();
    final int last = _frames.length - 1;
    final int target = stepIndex.clamp(0, last);
    setState(() => _currentStep = target);
    _checkCompletion();
  }

  void _handleTogglePlay() {
    final int last = _frames.length - 1;
    if (_isPlaying) {
      _stopPlayback();
    } else {
      if (_currentStep >= last) {
        // Replay from step 0
        setState(() => _currentStep = 0);
      }
      _startPlayback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalSteps = _frames.length;
    final int safeStep = _currentStep.clamp(0, totalSteps - 1);
    final AnimationFrame frame = _frames[safeStep];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Bar matching Web's `.sa-head`
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(color: AppColors.primaryBorder, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.lightAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ANIMATION',
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.lightAccent,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Step ${safeStep + 1} / $totalSteps',
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.lightAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 2. Animation Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              widget.animation.title,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // 3. Stage Canvas (Interactive Git visual objects, zones, edges)
          StageCanvas(frame: frame),

          // 4. Terminal Output (if present in frame)
          if (frame.term.isNotEmpty)
            TerminalView(
              lines: frame.term,
              step: safeStep,
            ),

          // 5. Current Step Explanation Caption matching Web's `.sa-say`
          if (frame.say != null && frame.say!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: AppColors.lightAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      frame.say!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMain,
                        height: 1.45,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 6. Playback Controls (Restart, Prev, Play/Pause/Replay, Next, Step Dots)
          AnimationControls(
            currentStep: safeStep,
            totalSteps: totalSteps,
            isPlaying: _isPlaying,
            onRestart: () => _goToStep(0),
            onPrev: () => _goToStep(safeStep - 1),
            onTogglePlay: _handleTogglePlay,
            onNext: () => _goToStep(safeStep + 1),
            onJumpToStep: _goToStep,
          ),
        ],
      ),
    );
  }
}
