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

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600.0;
  }

  @override
  void didUpdateWidget(covariant SubtopicAnimationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pathway != widget.pathway ||
        oldWidget.animationKey != widget.animationKey ||
        oldWidget.fallbackTitle != widget.fallbackTitle) {
      _loadFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    // 1. Warm cache: Synchronously render player immediately (0 frames latency, no flicker)
    if (AnimationLoader.cachedModules(pathway: widget.pathway, isMobile: isMobile) != null) {
      return _buildPlayer(isMobile);
    }

    // 2. Cold cache: Asynchronously load animations and render player once ready
    _loadFuture ??= AnimationLoader.loadAnimations(pathway: widget.pathway, isMobile: isMobile);

    return FutureBuilder<List<AnimationModule>>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200);
        }
        return _buildPlayer(isMobile);
      },
    );
  }

  Widget _buildPlayer(bool isMobile) {
    final SubtopicAnimation? animation =
        AnimationLoader.findAnimation(widget.animationKey, pathway: widget.pathway, isMobile: isMobile) ??
        AnimationLoader.findAnimation(widget.fallbackTitle, pathway: widget.pathway, isMobile: isMobile);

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
      key: ValueKey('${widget.pathway}_${animation.id}_${isMobile ? "m" : "d"}'),
      animation: animation,
      onFinish: widget.onFinish,
    );
  }
}
