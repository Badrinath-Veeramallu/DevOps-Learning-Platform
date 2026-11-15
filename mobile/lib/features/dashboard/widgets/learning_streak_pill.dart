import 'package:flutter/material.dart';
import '../../../models/streak_model.dart';

/// Clean, minimal streak pill matching Web's `LearningStreak.jsx` (variant="pill").
/// Displays thin outline Lucide Flame icon, bold streak count, and clean medium-weight 'streak' label.
class LearningStreakPill extends StatelessWidget {
  final StreakModel? streak;
  final bool isLoading;

  const LearningStreakPill({
    super.key,
    this.streak,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: 80,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFFCF7F8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFEAD9DC), width: 1),
        ),
      );
    }

    final currentStreak = streak?.currentStreak ?? 0;

    // Approved DevOps Platform Burgundy Palette
    const bgColor = Color(0xFFFCF7F8);
    const borderColor = Color(0xFFEAD9DC);
    const primaryBurgundy = Color(0xFF3B1F24);
    const flameBurgundy = Color(0xFF542B32);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const LucideFlameIcon(
            size: 15,
            color: flameBurgundy,
            strokeWidth: 2.0,
          ),
          const SizedBox(width: 4.5),
          Text(
            '$currentStreak',
            style: const TextStyle(
              color: primaryBurgundy,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 3.5),
          const Text(
            'streak',
            style: TextStyle(
              color: primaryBurgundy,
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
              height: 1.0,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Precise Lucide Flame Icon custom vector painter matching Web SVG path:
/// `M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z`
class LucideFlameIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const LucideFlameIcon({
    super.key,
    this.size = 15.0,
    this.color = const Color(0xFF542B32),
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _LucideFlamePainter(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _LucideFlamePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _LucideFlamePainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * (24.0 / size.width)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(8.5, 14.5);
    path.arcToPoint(
      const Offset(11, 12),
      radius: const Radius.circular(2.5),
      clockwise: false,
    );
    path.relativeCubicTo(0, -1.38, -0.5, -2.0, -1.0, -3.0);
    path.relativeCubicTo(-1.072, -2.143, -0.224, -4.054, 2.0, -6.0);
    path.relativeCubicTo(0.5, 2.5, 2.0, 4.9, 4.0, 6.5);
    path.relativeCubicTo(2.0, 1.6, 3.0, 3.5, 3.0, 5.5);
    path.arcToPoint(
      const Offset(5, 15),
      radius: const Radius.circular(7),
      largeArc: true,
      clockwise: true,
    );
    path.relativeCubicTo(0, -1.153, 0.433, -2.294, 1.0, -3.0);
    path.arcToPoint(
      const Offset(8.5, 14.5),
      radius: const Radius.circular(2.5),
      clockwise: false,
    );
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LucideFlamePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
