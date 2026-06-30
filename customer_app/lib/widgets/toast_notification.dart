import 'package:flutter/material.dart';

import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart' show AppRadius;
import 'package:ecom/theme/app_typography.dart';

/// Semantic flavour for a [ToastNotification]. Drives the snackbar background.
enum ToastType { info, success, error, warning }

/// Thin wrapper over [ScaffoldMessenger.showSnackBar], used everywhere instead
/// of `Fluttertoast`. See `docs/COMPONENT_SPEC.md` §5.
class ToastNotification {
  ToastNotification._(); // static-only API, never instantiated.

  /// Shows a transient 3s floating snackbar for [message].
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.body.copyWith(color: AppColors.surface),
        ),
        backgroundColor: _resolveColor(type),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Color _resolveColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return AppColors.success;
      case ToastType.error:
        return AppColors.error;
      case ToastType.warning:
        return AppColors.warning;
      case ToastType.info:
        return AppColors.primaryDark;
    }
  }
}
