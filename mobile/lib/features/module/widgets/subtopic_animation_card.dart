import 'package:flutter/material.dart';

import '../../../models/animation_model.dart';
import '../../animations/services/animation_loader.dart';
import '../../animations/widgets/step_animation_player.dart';

/// Animation slot component connecting curriculum subtopics to the interactive animation engine.
///
/// Preserves exact subtopic association with `git_animations.json` and embeds the fully
/// interactive [StepAnimationPlayer].
class SubtopicAnimationCard extends StatelessWidget {
  final String animationKey;
  final String fallbackTitle;
  final VoidCallback? onFinish;

  const SubtopicAnimationCard({
    super.key,
    required this.animationKey,
    required this.fallbackTitle,
    this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final SubtopicAnimation? animation =
        AnimationLoader.findAnimation(animationKey) ??
        AnimationLoader.findAnimation(fallbackTitle);

    if (animation == null) {
      return const SizedBox.shrink();
    }

    return StepAnimationPlayer(
      key: ValueKey(animation.id),
      animation: animation,
      onFinish: onFinish,
    );
  }
}
