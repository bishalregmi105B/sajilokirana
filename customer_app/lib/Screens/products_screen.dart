import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ecom/Services/Providers/cart.provider.dart';
import 'package:ecom/Services/Providers/catalog.provider.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/widgets/empty_state.dart';
import 'package:ecom/widgets/loading_shimmer.dart';
import 'package:ecom/widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.categoryName});

  final String categoryName;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().filterByCategory(widget.categoryName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
            onPressed: () => Navigator.of(context).pushNamed('/search'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final catalog = context.watch<CatalogProvider>();
    final cart = context.read<CartProvider>();

    if (catalog.isLoading) return LoadingShimmer.grid();

    if (catalog.error != null) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Could not load products',
        message: 'Check your connection and try again.',
        actionLabel: 'Retry',
        onAction: () =>
            catalog.filterByCategory(widget.categoryName),
      );
    }

    final items = catalog.byCategory(widget.categoryName);

    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_basket_outlined,
        title: 'No products yet',
        message: 'There are no products in ${widget.categoryName} at the moment.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final product = items[i];
        return Consumer<CartProvider>(
          builder: (_, cartState, __) => ProductCard(
            name: product.name,
            price: product.minPrice ?? 0,
            unit: product.unit,
            isInStock: product.inStock,
            initialQty: cartState.qtyFor(product.id),
            onAdd: product.inStock
                ? () => cart.addItem(
                      productId: product.id,
                      name: product.name,
                      unit: product.unit,
                      price: product.minPrice ?? 0,
                    )
                : null,
            onQtyChanged: product.inStock
                ? (q) => cart.setQty(product.id, q)
                : null,
            onTap: () => Navigator.of(ctx)
                .pushNamed('/product/detail', arguments: product),
          ),
        );
      },
    );
  }
}
