import 'package:flutter/material.dart';

import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';

/// Shared card container. Rounded (radius 12), subtle border, optional soft
/// shadow + tap. See `docs/COMPONENT_SPEC.md` §5.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.onTap,
    this.borderColor,
    this.background = AppColors.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final Decoration decoration = BoxDecoration(
      color: background,
      borderRadius: AppRadius.cardBorder,
      border: Border.all(color: borderColor ?? AppColors.border),
      boxShadow: onTap != null ? AppElevation.card(context) : null,
    );

    if (onTap == null) {
      return Container(padding: padding, decoration: decoration, child: child);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        child: Container(padding: padding, decoration: decoration, child: child),
      ),
    );
  }
}
