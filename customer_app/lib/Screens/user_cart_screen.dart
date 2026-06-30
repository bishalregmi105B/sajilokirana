import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ecom/constants.dart';
import 'package:ecom/Services/Providers/cart.provider.dart';
import 'package:ecom/Services/Providers/orders.provider.dart';
import 'package:ecom/Services/Exceptions/api_exception.dart';
import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_button.dart';
import 'package:ecom/widgets/app_card.dart';
import 'package:ecom/widgets/empty_state.dart';
import 'package:ecom/widgets/quantity_stepper.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isPlacingOrder = false;

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final orders = context.read<OrdersProvider>();

    if (cart.isEmpty) return;

    setState(() => _isPlacingOrder = true);
    try {
      // Default delivery address (lat/lng of central Kathmandu).
      // In production this should come from the user's selected saved address.
      final order = await orders.placeOrder(
        items: cart.toOrderItems(),
        deliveryAddress: {
          'label': 'Home',
          'line1': 'Kathmandu',
          'city': 'Kathmandu',
          'lat': 27.7172,
          'lng': 85.3240,
        },
      );
      if (!mounted) return;
      cart.clear();
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/order/confirm',
        (r) => r.settings.name == '/home',
        arguments: order?.id,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not place order. Check your connection.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: Consumer<CartProvider>(
        builder: (_, cart, __) => cart.isEmpty
            ? EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Your cart is empty',
                message: 'Add items from the home screen to start your order.',
                actionLabel: 'Browse products',
                onAction: () => Navigator.of(context).pop(),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        // ── Cart items ───────────────────────────────────
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Items', style: AppTypography.label),
                              const SizedBox(height: AppSpacing.sm),
                              ...cart.items.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.sm),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceTint,
                                            borderRadius: AppRadius.cardBorder,
                                          ),
                                          child: const Icon(
                                            Icons.image_outlined,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(item.name,
                                                  style: AppTypography.body,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis),
                                              Text(item.unit,
                                                  style: AppTypography.caption),
                                              Text(
                                                '$appCurrencySymbol${item.lineTotal.toStringAsFixed(0)}',
                                                style: AppTypography.label
                                                    .copyWith(
                                                        color: AppColors.primary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        QuantityStepper(
                                          qty: item.qty,
                                          onChanged: (q) =>
                                              cart.setQty(item.productId, q),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // ── Bill summary ─────────────────────────────────
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bill Summary', style: AppTypography.label),
                              const SizedBox(height: AppSpacing.sm),
                              _BillRow(
                                label: 'Subtotal',
                                value:
                                    '$appCurrencySymbol${cart.subtotal.toStringAsFixed(0)}',
                              ),
                              _BillRow(
                                label: 'Delivery',
                                value: cart.deliveryFee == 0
                                    ? 'Free'
                                    : '$appCurrencySymbol${cart.deliveryFee.toStringAsFixed(0)}',
                              ),
                              const Divider(height: AppSpacing.xl),
                              _BillRow(
                                label: 'Total',
                                value:
                                    '$appCurrencySymbol${cart.total.toStringAsFixed(0)}',
                                isBold: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // ── Cancellation policy ──────────────────────────
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cancellation Policy',
                                  style: AppTypography.label),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Orders cannot be cancelled once the shop has accepted them. '
                                'In case of unavailability, a full refund will be issued within 3–5 business days.',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                  // ── Sticky checkout footer ───────────────────────────────
                  _CheckoutFooter(
                    total: cart.total,
                    itemCount: cart.itemCount,
                    isLoading: _isPlacingOrder,
                    onCheckout: _placeOrder,
                  ),
                ],
              ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? AppTypography.bodyLarge : AppTypography.body,
          ),
          Text(
            value,
            style: isBold
                ? AppTypography.bodyLarge
                    .copyWith(color: AppColors.primary)
                : AppTypography.body,
          ),
        ],
      ),
    );
  }
}

class _CheckoutFooter extends StatelessWidget {
  const _CheckoutFooter({
    required this.total,
    required this.itemCount,
    required this.isLoading,
    required this.onCheckout,
  });
  final double total;
  final int itemCount;
  final bool isLoading;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$appCurrencySymbol${total.toStringAsFixed(0)}',
                style: AppTypography.bodyLarge,
              ),
              Text(
                '$itemCount item${itemCount == 1 ? '' : 's'}',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: AppButton(
              label: 'Place Order',
              isFullWidth: true,
              isLoading: isLoading,
              onPressed: isLoading ? null : onCheckout,
            ),
          ),
        ],
      ),
    );
  }
}


