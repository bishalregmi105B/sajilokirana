import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ecom/constants.dart';
import 'package:ecom/Services/Providers/orders.provider.dart';
import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_button.dart';
import 'package:ecom/widgets/app_card.dart';
import 'package:ecom/widgets/loading_shimmer.dart';
import 'package:ecom/widgets/order_status_badge.dart';

/// Order detail/summary screen.
/// Route: /order/summary   Arguments: orderId (String)
class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  AppOrder? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) _load();
  }

  Future<void> _load() async {
    final orderId = ModalRoute.of(context)?.settings.arguments as String?;
    if (orderId == null) {
      setState(() { _isLoading = false; _error = 'Order ID missing'; });
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final order = await context.read<OrdersProvider>().fetchOne(orderId);
      if (mounted) setState(() { _order = order; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: _isLoading
          ? LoadingShimmer.list()
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: AppTypography.body.copyWith(color: AppColors.error)),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(label: 'Retry', onPressed: _load),
                  ],
                ))
              : _order == null
                  ? const Center(child: Text('Order not found'))
                  : Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            AppCard(
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.12),
                                      borderRadius: AppRadius.cardBorder,
                                    ),
                                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.success),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_order!.itemSummary, style: AppTypography.bodyLarge),
                                        Text(_formatDate(_order!.createdAt), style: AppTypography.caption),
                                      ],
                                    ),
                                  ),
                                  OrderStatusBadge(status: _order!.status),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Items', style: AppTypography.label),
                                  const SizedBox(height: AppSpacing.sm),
                                  ..._order!.items.map((raw) {
                                    final item = raw as Map;
                                    final product = item['product'] as Map?;
                                    final name = product?['name'] as String? ?? 'Item';
                                    final unit = product?['unit'] as String? ?? '';
                                    final qty = item['qty'] as int? ?? 1;
                                    final price = (item['unitPrice'] as num?)?.toDouble() ?? 0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(name, style: AppTypography.body),
                                                Text('$unit · x$qty', style: AppTypography.caption),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '$appCurrencySymbol${(price * qty).toStringAsFixed(0)}',
                                            style: AppTypography.body,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const Divider(height: AppSpacing.xl),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total', style: AppTypography.bodyLarge),
                                      Text(
                                        '$appCurrencySymbol${_order!.totalAmount.toStringAsFixed(0)}',
                                        style: AppTypography.bodyLarge.copyWith(color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: 'Track Order',
                              variant: AppButtonVariant.secondary,
                              isFullWidth: true,
                              onPressed: () => Navigator.of(context).pushNamed(
                                '/order/track',
                                arguments: _order!.id,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
    );
  }
}
