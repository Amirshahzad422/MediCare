import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

enum ButtonVariant { primary, secondary, outline, danger }

class SharedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double? height;
  final bool expanded;

  const SharedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.expanded = true,
  });

  Color get _backgroundColor {
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.deepBlue;
      case ButtonVariant.secondary:
        return AppColors.mediumBlue;
      case ButtonVariant.outline:
        return AppColors.white;
      case ButtonVariant.danger:
        return AppColors.error;
    }
  }

  Color get _foregroundColor {
    switch (variant) {
      case ButtonVariant.outline:
        return AppColors.deepBlue;
      default:
        return AppColors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _backgroundColor,
        foregroundColor: _foregroundColor,
        disabledBackgroundColor: AppColors.iceBlue,
        minimumSize: Size(expanded ? double.infinity : 1, height ?? 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
        side: variant == ButtonVariant.outline
            ? const BorderSide(color: AppColors.lightBlue)
            : BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
            )
          : Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.buttonText,
                  ),
                ),
              ],
            ),
    );

    if (width == null) return btn;
    return SizedBox(width: width, child: btn);
  }
}