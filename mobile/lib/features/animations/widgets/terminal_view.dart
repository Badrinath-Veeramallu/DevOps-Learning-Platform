import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Embedded Terminal viewer displaying typed commands and Git output.
///
/// Matches Web's `.sa-term` with prompt highlight and command status coloring.
class TerminalView extends StatefulWidget {
  final List<String> lines;
  final int step;

  const TerminalView({
    super.key,
    required this.lines,
    required this.step,
  });

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant TerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines.length != oldWidget.lines.length ||
        widget.step != oldWidget.step) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0B17),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Window Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF2E171B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                _buildDot(const Color(0xFFEF4444)),
                const SizedBox(width: 5),
                _buildDot(const Color(0xFFF59E0B)),
                const SizedBox(width: 5),
                _buildDot(const Color(0xFF10B981)),
                const SizedBox(width: 8),
                const Text(
                  'terminal',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightAccent,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Terminal Body
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 125),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.lines.map(_buildTerminalLine).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTerminalLine(String line) {
    final bool isCmd = line.startsWith(r'$ ');
    final String tone = !isCmd && line.isNotEmpty && r'+~!' .contains(line[0])
        ? line[0]
        : '';
    final String text = tone.isNotEmpty ? line.substring(1) : line;

    if (isCmd) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: r'$ ',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightAccent,
                ),
              ),
              TextSpan(
                text: text.substring(2),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Color textColor = switch (tone) {
      '+' => AppColors.success,
      '~' => AppColors.warning,
      '!' => AppColors.error,
      _ => AppColors.textMuted,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10.5,
          height: 1.35,
          color: textColor,
        ),
      ),
    );
  }
}

