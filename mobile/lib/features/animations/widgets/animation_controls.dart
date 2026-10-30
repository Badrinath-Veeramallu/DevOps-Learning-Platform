import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Full interactive playback controls matching Web's `.sa-ctrl`.
class AnimationControls extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isPlaying;
  final VoidCallback onRestart;
  final VoidCallback onPrev;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final ValueChanged<int> onJumpToStep;

  const AnimationControls({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.isPlaying,
    required this.onRestart,
    required this.onPrev,
    required this.onTogglePlay,
    required this.onNext,
    required this.onJumpToStep,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAtFirst = currentStep == 0;
    final bool isAtLast = currentStep >= totalSteps - 1;

    final String playLabel = isPlaying
        ? '❚❚ Pause'
        : isAtLast
            ? '↻ Replay'
            : '▶ Play';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
        border: Border(
          top: BorderSide(color: AppColors.primaryBorder, width: 1),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 8,
        children: [
          // Control Buttons Group
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Restart Button
                _buildBtn(
                  onPressed: onRestart,
                  child: const Text(
                    '↺',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  tooltip: 'Restart',
                ),
                const SizedBox(width: 5),

                // Previous Button
                _buildBtn(
                  onPressed: isAtFirst ? null : onPrev,
                  child: const Text(
                    '‹',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  tooltip: 'Previous Step',
                ),
                const SizedBox(width: 5),

                // Primary Play/Pause/Replay Button
                ElevatedButton(
                  onPressed: onTogglePlay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: AppColors.primaryLight,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    playLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 5),

                // Next Button
                _buildBtn(
                  onPressed: isAtLast ? null : onNext,
                  child: const Text(
                    '›',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  tooltip: 'Next Step',
                ),
              ],
            ),
          ),

          // Step Dots Progress Indicator
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(totalSteps, (idx) {
                final bool isCurrent = idx == currentStep;
                final bool isDone = idx < currentStep;

                final Color dotColor = isCurrent
                    ? AppColors.lightAccent
                    : isDone
                        ? AppColors.primaryLight
                        : AppColors.borderHover;

                return InkWell(
                  onTap: () => onJumpToStep(idx),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isCurrent ? 12 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dotColor,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.lightAccent.withValues(alpha: 0.6),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBtn({
    required VoidCallback? onPressed,
    required Widget child,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textMain,
          disabledForegroundColor: AppColors.textSubtle.withValues(alpha: 0.3),
          side: BorderSide(
            color: onPressed != null
                ? AppColors.primaryBorder
                : AppColors.borderDefault.withValues(alpha: 0.4),
          ),
          backgroundColor: AppColors.surfaceElevated,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(36, 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: child,
      ),
    );
  }
}
