import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ecom/Services/Providers/cart.provider.dart';
import 'package:ecom/Services/Providers/catalog.provider.dart';
import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_search_bar.dart';
import 'package:ecom/widgets/bottom_nav_bar.dart';
import 'package:ecom/widgets/empty_state.dart';
import 'package:ecom/widgets/loading_shimmer.dart';
import 'package:ecom/widgets/product_card.dart';

import 'search_screen.dart';
import 'user_orders_screen.dart';
import 'profile_screen.dart';

/// Main app shell — hosts the four-tab navigation via [AppBottomNavBar].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppNavTab _tab = AppNavTab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab.index,
        children: const [
          _HomeTab(),
          SearchScreen(),
          OrdersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        current: _tab,
        onChanged: (t) => setState(() => _tab = t),
      ),
    );
  }
}

// ─── Home tab content ────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final cart = context.read<CartProvider>();

    final displayProducts = _selectedCategory != null
        ? catalog.byCategory(_selectedCategory!)
        : catalog.products;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Sticky app bar ───────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
            titleSpacing: AppSpacing.lg,
            title: _DeliveryHeader(),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    tooltip: 'Cart',
                    onPressed: () => Navigator.of(context).pushNamed('/cart'),
                  ),
                  Consumer<CartProvider>(
                    builder: (_, cart, __) => cart.isEmpty
                        ? const SizedBox.shrink()
                        : Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${cart.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border_rounded),
                tooltip: 'Wishlist',
                onPressed: () => Navigator.of(context).pushNamed('/wishlist'),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'Notifications',
                onPressed: () =>
                    Navigator.of(context).pushNamed('/notifications'),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),

          // ── Tappable search bar ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: AppSearchBar(
                onTap: () => Navigator.of(context).pushNamed('/search'),
              ),
            ),
          ),

          // ── Promo banner ─────────────────────────────────────────────────
          SliverToBoxAdapter(child: _PromoBanner()),

          // ── Categories header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm,
              ),
              child: Text('Shop by category', style: AppTypography.headline),
            ),
          ),

          // ── Category chips (horizontal scroll) ──────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  // "All" chip
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = null),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                    ),
                  ),
                  ...catalog.categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Popular items header ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedCategory ?? 'Popular items',
                      style: AppTypography.headline,
                    ),
                  ),
                  if (catalog.error != null)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Retry',
                      onPressed: () => catalog.refresh(),
                    ),
                ],
              ),
            ),
          ),

          // ── Product grid ─────────────────────────────────────────────────
          if (catalog.isLoading)
            SliverToBoxAdapter(child: LoadingShimmer.grid())
          else if (catalog.error != null && displayProducts.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Could not load products',
                message: 'Check your connection and try again.',
                actionLabel: 'Retry',
                onAction: () => catalog.refresh(),
              ),
            )
          else if (displayProducts.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No products yet',
                message: 'Check back soon.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final product = displayProducts[i];
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
                        onTap: () => Navigator.of(ctx).pushNamed(
                          '/product/detail',
                          arguments: product,
                        ),
                      ),
                    );
                  },
                  childCount: displayProducts.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

// ── Widgets used only in _HomeTab ───────────────────────────────────────────

class _DeliveryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/user/address'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded,
              color: AppColors.primary, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Deliver to', style: AppTypography.caption),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Kathmandu, Ward 10', style: AppTypography.label),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.cardBorder,
      ),
      padding: AppSpacing.card,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: Text(
                    'FREE DELIVERY',
                    style:
                        AppTypography.label.copyWith(color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'रु100 off on\nyour first order',
                  style: AppTypography.headline
                      .copyWith(color: AppColors.surface),
                ),
              ],
            ),
          ),
          Image.asset(
            'Assets/Images/gift.jpg',
            height: 110,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(width: 80),
          ),
        ],
      ),
    );
  }
}

