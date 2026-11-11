import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum ButtonVariant { primary, secondary, ghost }

/// Reusable button widget adhering to the Website White + Burgundy design system.
///
/// Features:
/// - Primary: Deep burgundy background with soft shadow and crisp white text
/// - Secondary: Crisp white surface with subtle burgundy border and burgundy text
/// - Ghost: Transparent with muted text
/// - Built-in loading state with centered spinner
/// - Full-width or content-sized layout
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final bool isFullWidth;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;

    Widget child;
    if (isLoading) {
      child = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ButtonVariant.primary
                ? Colors.white
                : AppColors.primary,
          ),
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text, style: _getTextStyle()),
        ],
      );
    } else {
      child = Text(text, style: _getTextStyle());
    }

    Widget buttonWidget;
    switch (variant) {
      case ButtonVariant.primary:
        buttonWidget = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: AppColors.borderDefault,
              disabledForegroundColor: AppColors.textSubtle,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: child,
          ),
        );
        break;

      case ButtonVariant.secondary:
        buttonWidget = OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.textSubtle,
            side: BorderSide(
              color: enabled
                  ? AppColors.borderDefault
                  : AppColors.borderSubtle,
              width: 1.2,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: child,
        );
        break;

      case ButtonVariant.ghost:
        buttonWidget = TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textMuted,
            disabledForegroundColor: AppColors.textSubtle,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: child,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: buttonWidget,
      );
    }

    return SizedBox(height: height, child: buttonWidget);
  }

  TextStyle _getTextStyle() {
    switch (variant) {
      case ButtonVariant.primary:
        return AppTypography.buttonText.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        );
      case ButtonVariant.secondary:
        return AppTypography.buttonText.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        );
      case ButtonVariant.ghost:
        return AppTypography.buttonText.copyWith(color: AppColors.textMuted);
    }
  }
}
