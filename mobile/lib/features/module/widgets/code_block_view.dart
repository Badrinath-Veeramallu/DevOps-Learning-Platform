import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Interactive, horizontally scrollable code snippet card for mobile devices.
///
/// Matches Web's `.code-block-container` with language label and copy-to-clipboard button.
class CodeBlockView extends StatefulWidget {
  final String code;
  final String language;

  const CodeBlockView({
    super.key,
    required this.code,
    this.language = 'bash',
  });

  @override
  State<CodeBlockView> createState() => _CodeBlockViewState();
}

class _CodeBlockViewState extends State<CodeBlockView> {
  bool _isCopied = false;

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.code));
    if (mounted) {
      setState(() => _isCopied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isCopied = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Language & Copy Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
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
                    const Icon(
                      Icons.terminal_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.language.toUpperCase(),
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _handleCopy,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isCopied
                              ? Icons.check_rounded
                              : Icons.copy_rounded,
                          size: 13,
                          color: _isCopied
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isCopied ? 'Copied!' : 'Copy',
                          style: AppTypography.bodySmall.copyWith(
                            color: _isCopied
                                ? AppColors.success
                                : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Code Content (Horizontal Scrollable)
          Padding(
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SelectableText(
                widget.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.55,
                  color: AppColors.textMain,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
