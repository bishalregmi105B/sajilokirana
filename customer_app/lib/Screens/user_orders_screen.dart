import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ecom/constants.dart';
import 'package:ecom/Services/Providers/orders.provider.dart';
import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_card.dart';
import 'package:ecom/widgets/empty_state.dart';
import 'package:ecom/widgets/loading_shimmer.dart';
import 'package:ecom/widgets/order_status_badge.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: Consumer<OrdersProvider>(
        builder: (_, orders, __) {
          if (orders.isLoading) return LoadingShimmer.list();

          if (orders.error != null && orders.orders.isEmpty) {
            return EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Could not load orders',
              message: 'Check your connection and try again.',
              actionLabel: 'Retry',
              onAction: () => orders.load(),
            );
          }

          if (orders.orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: "You haven't placed any orders yet.",
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => orders.load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: orders.orders.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) {
                final order = orders.orders[i];
                return _OrderRow(
                  order: order,
                  onTap: () => Navigator.of(ctx).pushNamed(
                    '/order',
                    arguments: order.id,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.onTap});
  final AppOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.itemSummary,
                  style: AppTypography.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                '$appCurrencySymbol${order.totalAmount.toStringAsFixed(0)}',
                style: AppTypography.body.copyWith(color: AppColors.textMuted),
              ),
              Text(
                '  ·  ${_formatDate(order.createdAt)}',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'View Details →',
              style: AppTypography.label.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
