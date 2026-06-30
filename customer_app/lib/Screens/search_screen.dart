import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ecom/Services/Providers/cart.provider.dart';
import 'package:ecom/Services/Providers/catalog.provider.dart';
import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_search_bar.dart';
import 'package:ecom/widgets/empty_state.dart';
import 'package:ecom/widgets/loading_shimmer.dart';
import 'package:ecom/widgets/product_card.dart';

/// Full-page search screen. Used both as a tab in HomeScreen and as a
/// push route from product/category screens.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    setState(() => _query = q);
    if (q.trim().isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<CatalogProvider>().search(q.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.sm,
        title: AppSearchBar(
          controller: _ctrl,
          hintText: 'Search for dal, chiura, tarkari…',
          onChanged: _onQueryChanged,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text('Cancel',
                style: AppTypography.body.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final catalog = context.watch<CatalogProvider>();

    if (catalog.isLoading && _query.isNotEmpty) return LoadingShimmer.grid();

    if (_query.isEmpty) {
      return _RecentSearches(categories: catalog.categories);
    }

    final results = catalog.products
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results for "$_query"',
        message: 'Try a different spelling or search for something else.',
      );
    }

    final cart = context.read<CartProvider>();

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.72,
      ),
      itemCount: results.length,
      itemBuilder: (ctx, i) {
        final product = results[i];
        return Consumer<CartProvider>(
          builder: (_, cartState, __) => ProductCard(
            name: product.name,
            price: product.minPrice ?? 0,
            unit: product.unit,
            isInStock: product.inStock,
            initialQty: cartState.qtyFor(product.id),
            onAdd: () => cart.addItem(
              productId: product.id,
              name: product.name,
              unit: product.unit,
              price: product.minPrice ?? 0,
            ),
            onQtyChanged: (q) => cart.setQty(product.id, q),
            onTap: () => Navigator.of(ctx)
                .pushNamed('/product/detail', arguments: product),
          ),
        );
      },
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({required this.categories});
  final List<String> categories;

  static const _recents = ['Wai Wai', 'Mustard Oil', 'Dahi', 'Aata'];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Recent searches', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _recents
              .map((r) => ActionChip(
                    label: Text(r, style: AppTypography.caption),
                    onPressed: () {},
                  ))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Popular categories', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: categories
              .take(8)
              .map((c) => ActionChip(
                    label: Text(c, style: AppTypography.caption),
                    onPressed: () => Navigator.of(context).pushNamed(
                      '/products',
                      arguments: c,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
