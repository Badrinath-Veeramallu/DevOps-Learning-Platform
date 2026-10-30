import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/curriculum_model.dart';
import 'code_block_view.dart';
import 'subtopic_animation_card.dart';

/// Full educational content renderer preserving 100% of the Web curriculum structures.
///
/// Supports headings, paragraphs, external links, code snippets, lists, and animation slots.
class LearningContentRenderer extends StatelessWidget {
  final CurriculumSection section;
  final String moduleNumber;
  final VoidCallback? onAnimationFinish;

  const LearningContentRenderer({
    super.key,
    required this.section,
    required this.moduleNumber,
    this.onAnimationFinish,
  });

  void _handleCopyLink(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied link: $url'),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMain,
          height: 1.65,
          fontSize: 14.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanSectionTitle = section.title;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtopic Title Heading
          Text(
            cleanSectionTitle,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w700,
              fontSize: 19,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderDefault, height: 1),
          const SizedBox(height: 16),

          // Primary Paragraphs
          ...section.paragraphs.map(_buildParagraph),

          // Optional External Reference Link
          if (section.link != null) ...[
            InkWell(
              onTap: () => _handleCopyLink(context, section.link!.url),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderDefault, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      size: 16,
                      color: AppColors.lightAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        section.link!.text,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.lightAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Paragraphs after Link
          if (section.afterLinkParagraphs != null)
            ...section.afterLinkParagraphs!.map(_buildParagraph),

          // Code Snippet 1
          if (section.codeSnippet != null)
            CodeBlockView(
              code: section.codeSnippet!.code,
              language: section.codeSnippet!.language,
            ),

          // Paragraphs after Snippet 1
          if (section.postSnippetParagraphs != null)
            ...section.postSnippetParagraphs!.map(_buildParagraph),

          // Code Snippet 2
          if (section.secondSnippet != null)
            CodeBlockView(
              code: section.secondSnippet!.code,
              language: section.secondSnippet!.language,
            ),

          // Middle Paragraphs
          if (section.middleParagraphs != null)
            ...section.middleParagraphs!.map(_buildParagraph),

          // Code Snippet 3
          if (section.thirdSnippet != null)
            CodeBlockView(
              code: section.thirdSnippet!.code,
              language: section.thirdSnippet!.language,
            ),

          // Paragraphs after Snippet 3
          if (section.afterThirdParagraphs != null)
            ...section.afterThirdParagraphs!.map(_buildParagraph),

          // Code Snippet 4
          if (section.fourthSnippet != null)
            CodeBlockView(
              code: section.fourthSnippet!.code,
              language: section.fourthSnippet!.language,
            ),

          // Bullet List Items
          if (section.listItems != null && section.listItems!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: section.listItems!
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 7),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.lightAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMain,
                                  height: 1.5,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          // Closing Paragraphs
          if (section.closingParagraphs != null)
            ...section.closingParagraphs!.map(_buildParagraph),

          // Subtopic Animation Slot
          SubtopicAnimationCard(
            animationKey: '$moduleNumber.${section.number}',
            fallbackTitle: section.title,
            onFinish: onAnimationFinish,
          ),
        ],
      ),
    );
  }
}

