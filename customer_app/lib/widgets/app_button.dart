import 'package:flutter/material.dart';

import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/theme/app_spacing.dart';

/// Variant of [AppButton].
enum AppButtonVariant { primary, secondary, text }

/// SajiloKirana shared button. Primary (filled terracotta), secondary
/// (outlined), or text. Supports a leading icon, a loading state, full-width
/// sizing, and a destructive flavour. See `docs/COMPONENT_SPEC.md` §5.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final bool isDestructive;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    // Destructive only recolors the primary variant.
    final Color primaryFill =
        isDestructive ? AppColors.error : AppColors.primary;

    final Widget content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.primary
                    ? AppColors.surface
                    : primaryFill,
              ),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label, style: AppTypography.button),
            ],
          );

    final VoidCallback? callback = _enabled ? onPressed : null;

    switch (variant) {
      case AppButtonVariant.primary:
        return FilledButton(
          onPressed: callback,
          style: FilledButton.styleFrom(
            backgroundColor: primaryFill,
            foregroundColor: AppColors.surface,
            minimumSize: Size.fromHeight(isFullWidth ? 48 : 0),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          child: content,
        );
      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: callback,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDestructive ? AppColors.error : AppColors.primary,
            minimumSize: Size.fromHeight(isFullWidth ? 48 : 0),
            side: BorderSide(
              color: isDestructive ? AppColors.error : AppColors.primary,
              width: 1.5,
            ),
          ),
          child: content,
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: callback,
          style: TextButton.styleFrom(
            foregroundColor:
                isDestructive ? AppColors.error : AppColors.primary,
          ),
          child: content,
        );
    }
  }
}
