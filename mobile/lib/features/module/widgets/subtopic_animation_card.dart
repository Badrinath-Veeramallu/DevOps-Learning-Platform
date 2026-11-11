import 'package:flutter/material.dart';

import '../../../models/animation_model.dart';
import '../../animations/services/animation_loader.dart';
import '../../animations/widgets/step_animation_player.dart';

/// Animation slot component connecting curriculum subtopics to the interactive animation engine.
///
/// Preserves exact subtopic association with animation assets and embeds the fully
/// interactive [StepAnimationPlayer].
class SubtopicAnimationCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final SubtopicAnimation? animation =
        AnimationLoader.findAnimation(animationKey, pathway: pathway) ??
        AnimationLoader.findAnimation(fallbackTitle, pathway: pathway);

    if (animation == null) {
      return const SizedBox.shrink();
    }

    return StepAnimationPlayer(
      key: ValueKey('${pathway}_${animation.id}'),
      animation: animation,
      onFinish: onFinish,
    );
  }
}
