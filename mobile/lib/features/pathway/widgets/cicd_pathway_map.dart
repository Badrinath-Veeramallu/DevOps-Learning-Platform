import 'package:flutter/material.dart';

import '../../../models/curriculum_model.dart';
import 'git_pathway_map.dart';

/// Interactive curved learning pathway map for CI/CD & GitOps Delivery.
/// Reuses the continuous cubic-Bézier winding road layout with CI/CD milestone finish.
class CicdPathwayMap extends StatelessWidget {
  final List<CurriculumModule> modules;
  final Set<String> completedModuleIds;
  final ValueChanged<String> onSelectModule;
  final VoidCallback? onFinishTap;
  final String finishText;

  const CicdPathwayMap({
    super.key,
    required this.modules,
    required this.completedModuleIds,
    required this.onSelectModule,
    this.onFinishTap,
    this.finishText = 'CI/CD & GitOps Delivery Mastered!',
  });

  @override
  Widget build(BuildContext context) {
    return GitPathwayMap(
      modules: modules,
      completedModuleIds: completedModuleIds,
      onSelectModule: onSelectModule,
      onFinishTap: onFinishTap,
      finishText: finishText,
    );
  }
}
