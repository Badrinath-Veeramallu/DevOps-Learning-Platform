import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Crisp, standalone vector representation of the official Google 4-color 'G' logo.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Blue horizontal bar and right arc
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final bluePath = Path()
      ..moveTo(w * 0.96, h * 0.5)
      ..arcTo(
        Rect.fromLTWH(0, 0, w, h),
        0.0,
        -0.785, // -45 deg
        false,
      )
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Main Google G paths scaled to 24x24 viewport
    final scale = w / 24.0;
    canvas.scale(scale, scale);

    // Blue section (Right bar & lower-right quadrant)
    final pBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final pathBlue = Path()
      ..moveTo(23.745, 12.27)
      ..cubicTo(23.745, 11.48, 23.675, 10.73, 23.55, 10)
      ..lineTo(12, 10)
      ..lineTo(12, 14.51)
      ..lineTo(18.59, 14.51)
      ..cubicTo(18.3, 16.03, 17.42, 17.32, 16.1, 18.2)
      ..lineTo(19.98, 21.2)
      ..cubicTo(22.25, 19.11, 23.745, 16.02, 23.745, 12.27)
      ..close();
    canvas.drawPath(pathBlue, pBlue);

    // Green section (Bottom quadrant)
    final pGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final pathGreen = Path()
      ..moveTo(12, 24)
      ..cubicTo(15.24, 24, 17.96, 22.92, 19.98, 21.2)
      ..lineTo(16.1, 18.2)
      ..cubicTo(15.02, 18.92, 13.63, 19.36, 12, 19.36)
      ..cubicTo(8.87, 19.36, 6.22, 17.25, 5.27, 14.41)
      ..lineTo(1.24, 17.53)
      ..cubicTo(3.26, 21.54, 7.31, 24, 12, 24)
      ..close();
    canvas.drawPath(pathGreen, pGreen);

    // Yellow section (Left quadrant)
    final pYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final pathYellow = Path()
      ..moveTo(5.27, 14.41)
      ..cubicTo(5.03, 13.68, 4.9, 12.87, 4.9, 12)
      ..cubicTo(4.9, 11.13, 5.03, 10.32, 5.27, 9.59)
      ..lineTo(1.24, 6.47)
      ..cubicTo(0.45, 8.04, 0, 9.94, 0, 12)
      ..cubicTo(0, 14.06, 0.45, 15.96, 1.24, 17.53)
      ..lineTo(5.27, 14.41)
      ..close();
    canvas.drawPath(pathYellow, pYellow);

    // Red section (Top quadrant)
    final pRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final pathRed = Path()
      ..moveTo(12, 4.64)
      ..cubicTo(13.76, 4.64, 15.34, 5.24, 16.58, 6.42)
      ..lineTo(19.95, 3.05)
      ..cubicTo(17.95, 1.16, 15.23, 0, 12, 0)
      ..cubicTo(7.31, 0, 3.26, 2.46, 1.24, 6.47)
      ..lineTo(5.27, 9.59)
      ..cubicTo(6.22, 6.75, 8.87, 4.64, 12, 4.64)
      ..close();
    canvas.drawPath(pathRed, pRed);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "Continue with Google" action button styled for the Cyber Midnight design system.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.text = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.7),
          foregroundColor: AppColors.textMain,
          disabledForegroundColor: AppColors.textSubtle,
          side: const BorderSide(color: AppColors.borderDefault, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GoogleLogo(size: 20),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: AppTypography.buttonText.copyWith(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Subtle "OR" horizontal divider for separating email/password forms from OAuth options.
class AuthDivider extends StatelessWidget {
  final String label;

  const AuthDivider({super.key, this.label = 'OR'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderDefault)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSubtle,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderDefault)),
      ],
    );
  }
}
