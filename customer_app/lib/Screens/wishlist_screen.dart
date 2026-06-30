import 'package:flutter/material.dart';

import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/empty_state.dart';
import 'package:ecom/widgets/product_card.dart';

/// Wishlist screen — products the user has saved for later.
/// Route: /wishlist
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  // Demo data — wire to local storage / API when backend is ready.
  final List<_WishItem> _items = [
    const _WishItem(name: 'Basmati Rice', price: 480, unit: '5kg bag'),
    const _WishItem(name: 'Masala Tea Leaves', price: 120, unit: '250g packet'),
    const _WishItem(name: 'Ghiu (Ghee)', price: 350, unit: '500ml'),
  ];

  void _remove(int i) => setState(() => _items.removeAt(i));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: _items.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Your wishlist is empty',
              message: 'Tap the heart icon on any product to save it here.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    '${_items.length} saved items',
                    style: AppTypography.label,
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final item = _items[i];
                      return Stack(
                        children: [
                          ProductCard(
                            name: item.name,
                            price: item.price,
                            unit: item.unit,
                            onAdd: () {},
                            onTap: () =>
                                Navigator.of(ctx).pushNamed('/product/detail'),
                          ),
                          Positioned(
                            top: AppSpacing.xs,
                            right: AppSpacing.xs,
                            child: IconButton(
                              icon: const Icon(Icons.favorite_rounded),
                              color: Theme.of(ctx).colorScheme.error,
                              tooltip: 'Remove from wishlist',
                              onPressed: () => _remove(i),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _WishItem {
  const _WishItem({
    required this.name,
    required this.price,
    required this.unit,
  });
  final String name;
  final double price;
  final String unit;
}
