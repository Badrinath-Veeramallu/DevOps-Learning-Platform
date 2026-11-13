import 'package:flutter/material.dart';

import '../../../models/animation_model.dart';
import '../../animations/services/animation_loader.dart';
import '../../animations/widgets/step_animation_player.dart';

/// Animation slot component connecting curriculum subtopics to the interactive animation engine.
///
/// Features:
/// - Reactive self-loading: automatically ensures pathway animations are loaded if cache is cold
/// - Zero flicker and zero frame latency when cache is warm
/// - Dynamic lookup by subtopic ID (e.g. "01.1", "1.1") and normalized title
/// - Diagnostic debug logging
/// - Embeds the fully interactive [StepAnimationPlayer]
class SubtopicAnimationCard extends StatefulWidget {
  final String animationKey;
  final String fallbackTitle;
  final VoidCallback? onFinish;
  final String pathway;

  const SubtopicAnimationCard({
    super.key,
    required this.animationKey,
    required this.fallbackTitle,
    this.onFinish,
    this.pathway = 'git',
  });

  @override
  State<SubtopicAnimationCard> createState() => _SubtopicAnimationCardState();
}

class _SubtopicAnimationCardState extends State<SubtopicAnimationCard> {
  Future<List<AnimationModule>>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _checkLoad();
  }

  @override
  void didUpdateWidget(covariant SubtopicAnimationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pathway != widget.pathway ||
        oldWidget.animationKey != widget.animationKey ||
        oldWidget.fallbackTitle != widget.fallbackTitle) {
      _checkLoad();
    }
  }

  void _checkLoad() {
    if (AnimationLoader.cachedModules(pathway: widget.pathway) == null) {
      _loadFuture = AnimationLoader.loadAnimations(pathway: widget.pathway);
    } else {
      _loadFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Warm cache: Synchronously render player immediately (0 frames latency, no flicker)
    if (AnimationLoader.cachedModules(pathway: widget.pathway) != null) {
      return _buildPlayer();
    }

    // 2. Cold cache: Asynchronously load animations and render player once ready
    _loadFuture ??= AnimationLoader.loadAnimations(pathway: widget.pathway);

    return FutureBuilder<List<AnimationModule>>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200);
        }
        return _buildPlayer();
      },
    );
  }

  Widget _buildPlayer() {
    final SubtopicAnimation? animation =
        AnimationLoader.findAnimation(widget.animationKey, pathway: widget.pathway) ??
        AnimationLoader.findAnimation(widget.fallbackTitle, pathway: widget.pathway);

    if (animation == null) {
      debugPrint(
        '[SubtopicAnimationCard] Animation not found for key: "${widget.animationKey}", title: "${widget.fallbackTitle}", pathway: "${widget.pathway}"',
      );
      return const SizedBox.shrink();
    }

    debugPrint(
      '[SubtopicAnimationCard] Rendering animation "${animation.id}" ("${animation.title}") for key: "${widget.animationKey}" on pathway: "${widget.pathway}"',
    );

    return StepAnimationPlayer(
      key: ValueKey('${widget.pathway}_${animation.id}'),
      animation: animation,
      onFinish: widget.onFinish,
    );
  }
}
