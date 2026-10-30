import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/animation_model.dart';
import '../services/step_engine.dart';

/// Renders a single Git animation actor matching Web's `Actor` component.
///
/// Supports all 7 actor shapes ('box', 'file', 'pill', 'commit', 'zone', 'code', 'note')
/// and all 7 tone variants ('plain', 'soft', 'brand', 'warn', 'ok', 'bad', 'dim').
class ActorWidget extends StatelessWidget {
  final ActorModel actor;
  final double stageWidth;
  final double stageHeight;

  const ActorWidget({
    super.key,
    required this.actor,
    required this.stageWidth,
    required this.stageHeight,
  });

  ({Color bg, Color border, Color text}) _resolveTone(String? tone, String kind) {
    final t = tone ?? (kind == 'zone' ? 'soft' : 'plain');
    return switch (t) {
      'brand' => (
          bg: const Color(0xFF4A1E29),
          border: AppColors.lightAccent,
          text: Colors.white,
        ),
      'soft' => (
          bg: const Color(0x3382535D),
          border: const Color(0x66B88A91),
          text: const Color(0xFFE7D4D7),
        ),
      'warn' => (
          bg: const Color(0x2EF59E0B),
          border: const Color(0x80F59E0B),
          text: const Color(0xFFFDE68A),
        ),
      'ok' => (
          bg: const Color(0x2E10B981),
          border: const Color(0x8010B981),
          text: const Color(0xFFA7F3D0),
        ),
      'bad' => (
          bg: const Color(0x2EEF4444),
          border: const Color(0x80EF4444),
          text: const Color(0xFFFECACA),
        ),
      'dim' => (
          bg: const Color(0x1AFFFFFF),
          border: const Color(0x4094A3B8),
          text: const Color(0xFF64748B),
        ),
      _ => (
          bg: const Color(0xFF1E293B),
          border: const Color(0xFF334155),
          text: AppColors.textMain,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (actor.hide) {
      return const SizedBox.shrink();
    }

    final double posX = (actor.x / 100.0) * stageWidth;
    final double posY = (actor.y / 100.0) * stageHeight;

    final defaultW = StepEngine.defaultW[actor.k] ?? 16.0;
    final double? width = actor.w != null
        ? (actor.w! / 100.0) * stageWidth
        : (defaultW > 0 ? (defaultW / 100.0) * stageWidth : null);

    final double? height = actor.k == 'zone' && actor.h != null
        ? (actor.h! / 100.0) * stageHeight
        : null;

    final toneColors = _resolveTone(actor.tone, actor.k);

    return Positioned(
      left: posX,
      top: posY,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          child: _buildShape(context, toneColors),
        ),
      ),
    );
  }

  Widget _buildShape(BuildContext context, ({Color bg, Color border, Color text}) tone) {
    return switch (actor.k) {
      'commit' => _buildCommit(tone),
      'file' => _buildFile(tone),
      'pill' => _buildPill(tone),
      'zone' => _buildZone(tone),
      'code' => _buildCode(tone),
      'note' => _buildNote(tone),
      _ => _buildBox(tone),
    };
  }

  Widget _buildBox(({Color bg, Color border, Color text}) tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: tone.border, width: 1.2),
        boxShadow: actor.glow
            ? [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (actor.ic != null) ...[
                Text(
                  actor.ic!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: tone.text,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (actor.text != null)
                Flexible(
                  child: Text(
                    actor.text!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tone.text,
                      height: 1.2,
                    ),
                  ),
                ),
            ],
          ),
          if (actor.sub != null) ...[
            const SizedBox(height: 3),
            Text(
              actor.sub!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: tone.text.withValues(alpha: 0.8),
                height: 1.2,
              ),
            ),
          ],
          if (actor.bar != null) ...[
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (actor.bar! / 100.0).clamp(0.0, 1.0),
                backgroundColor: Colors.black26,
                valueColor: AlwaysStoppedAnimation<Color>(tone.text),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommit(({Color bg, Color border, Color text}) tone) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: tone.bg,
            shape: BoxShape.circle,
            border: Border.all(color: tone.border, width: 1.5),
            boxShadow: actor.glow
                ? [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            actor.text ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: tone.text,
            ),
          ),
        ),
        if (actor.sub != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              actor.sub!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFile(({Color bg, Color border, Color text}) tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
          topRight: Radius.circular(1),
        ),
        border: Border.all(color: tone.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file_outlined, size: 11, color: tone.text),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  actor.text ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: tone.text,
                  ),
                ),
              ),
            ],
          ),
          if (actor.sub != null) ...[
            const SizedBox(height: 2),
            Text(
              actor.sub!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
                color: tone.text.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPill(({Color bg, Color border, Color text}) tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (actor.ic != null) ...[
            Text(
              actor.ic!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: tone.text,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            actor.text ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: tone.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZone(({Color bg, Color border, Color text}) tone) {
    return Container(
      decoration: BoxDecoration(
        color: tone.bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tone.border,
          width: 1.2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 6,
            left: 10,
            child: Text(
              (actor.text ?? '').toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: tone.text.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCode(({Color bg, Color border, Color text}) tone) {
    final lines = actor.lines ?? const [];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13101C),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.primaryBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (actor.title != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF2E171B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.lightAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      actor.title!,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtleHighlight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: lines.map((l) {
                String lineText = '';
                String lineClass = '';

                if (l is List && l.isNotEmpty) {
                  lineText = l[0].toString();
                  if (l.length > 1) lineClass = l[1].toString();
                } else if (l != null) {
                  lineText = l.toString();
                }

                final Color lineBg = switch (lineClass) {
                  'add' => const Color(0x3310B981),
                  'del' => const Color(0x33EF4444),
                  'hl' => const Color(0x33F59E0B),
                  'cur' => const Color(0x4082535D),
                  _ => Colors.transparent,
                };

                final Color lineTextColor = switch (lineClass) {
                  'add' => const Color(0xFFA7F3D0),
                  'del' => const Color(0xFFFECACA),
                  'hl' => const Color(0xFFFDE68A),
                  'mark' => const Color(0xFFF472B6),
                  'dim' => const Color(0xFF64748B),
                  _ => AppColors.textMain,
                };

                return Container(
                  width: double.infinity,
                  color: lineBg,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Text(
                    lineText.isEmpty ? ' ' : lineText,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      height: 1.35,
                      color: lineTextColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNote(({Color bg, Color border, Color text}) tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tone.border, width: 1),
      ),
      child: Text(
        actor.text ?? '',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: tone.text,
        ),
      ),
    );
  }
}
