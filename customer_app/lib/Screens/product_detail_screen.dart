import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ecom/constants.dart';
import 'package:ecom/Services/Providers/cart.provider.dart';
import 'package:ecom/Services/Providers/catalog.provider.dart';
import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_button.dart';
import 'package:ecom/widgets/app_card.dart';
import 'package:ecom/widgets/quantity_stepper.dart';

/// Product detail — route: /product/detail, arguments: CatalogProduct
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)?.settings.arguments as CatalogProduct?;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Product not found')),
      );
    }

    return _ProductDetailView(product: product);
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView({required this.product});
  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.qtyFor(product.id);
    final price = product.minPrice;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.surfaceTint,
                child: const Icon(Icons.image_outlined,
                    size: 80, color: AppColors.textMuted),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: AppTypography.headline),
                            const SizedBox(height: AppSpacing.xs),
                            Text(product.unit, style: AppTypography.caption),
                          ],
                        ),
                      ),
                      if (!product.inStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: AppRadius.pillBorder,
                          ),
                          child: Text('Out of stock',
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.error)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (price != null)
                    Text(
                      '$appCurrencySymbol${price.toStringAsFixed(0)}',
                      style: AppTypography.displayMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category', style: AppTypography.label),
                        const SizedBox(height: AppSpacing.xs),
                        Text(product.category, style: AppTypography.body),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Product info', style: AppTypography.label),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Unit: ${product.unit}', style: AppTypography.body),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          product.inStock
                              ? 'Available from nearby shops'
                              : 'Currently unavailable',
                          style: AppTypography.caption.copyWith(
                            color: product.inStock
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: product.inStock && price != null
          ? Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
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
              child: qty == 0
                  ? AppButton(
                      label: 'Add to cart — $appCurrencySymbol${price.toStringAsFixed(0)}',
                      isFullWidth: true,
                      onPressed: () => context.read<CartProvider>().addItem(
                            productId: product.id,
                            name: product.name,
                            unit: product.unit,
                            price: price,
                          ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$appCurrencySymbol${(price * qty).toStringAsFixed(0)}',
                                style: AppTypography.bodyLarge,
                              ),
                              Text('$qty in cart', style: AppTypography.caption),
                            ],
                          ),
                        ),
                        QuantityStepper(
                          qty: qty,
                          onChanged: (q) =>
                              context.read<CartProvider>().setQty(product.id, q),
                        ),
                      ],
                    ),
            )
          : null,
    );
  }
}
