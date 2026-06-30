import 'package:flutter/material.dart';

import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';

/// Small status pill for an order row. Color from [AppColors.forOrderStatus];
/// label is a humanized version of the backend status string.
/// See `docs/COMPONENT_SPEC.md` §5.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  /// Backend status: pending | broadcasting | shop_confirmed | picked_up |
  /// in_transit | delivered | cancelled.
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forOrderStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text(
        _humanize(status),
        style: AppTypography.label.copyWith(color: color),
      ),
    );
  }

  static String _humanize(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'broadcasting':
        return 'Finding shop';
      case 'shop_confirmed':
        return 'Shop confirmed';
      case 'picked_up':
        return 'Picked up';
      case 'in_transit':
        return 'On the way';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        final spaced = status.replaceAll('_', ' ');
        if (spaced.isEmpty) return spaced;
        return spaced[0].toUpperCase() + spaced.substring(1);
    }
  }
}
