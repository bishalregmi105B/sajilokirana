import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import '../theme/colors.dart';
import '../constants.dart';
import '../widgets/stat_tile.dart';
import '../widgets/incoming_order_card.dart';

class ShopHomeScreen extends StatefulWidget {
  const ShopHomeScreen({super.key});
  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<ShopProvider>();
      sp.loadIncoming(); sp.loadActiveOrders(); sp.loadAnalytics(); sp.startPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthProvider>(builder: (_, auth, __) => Text(auth.shop?.shopName ?? 'Dashboard')),
        actions: [
          IconButton(icon: const Icon(Icons.bar_chart_rounded), onPressed: () => Navigator.of(context).pushNamed('/reliability')),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () async {
            context.read<ShopProvider>().stopPolling();
            await context.read<AuthProvider>().logout();
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          }),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          if (i == 1) Navigator.of(context).pushNamed('/orders');
          else if (i == 2) Navigator.of(context).pushNamed('/inventory');
          else if (i == 3) Navigator.of(context).pushNamed('/payouts');
          else setState(() => _navIndex = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Payouts'),
        ],
      ),
      body: Consumer<ShopProvider>(builder: (_, sp, __) {
        final a = sp.analytics;
        return RefreshIndicator(
          onRefresh: () async { await sp.loadIncoming(); await sp.loadAnalytics(); },
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              StatTile(label: "Today's orders", value: '${a?.orders.today ?? 0}', icon: Icons.receipt_long),
              StatTile(label: "Revenue", value: '$appCurrencySymbol ${(a?.revenue.today ?? 0).toStringAsFixed(0)}', icon: Icons.payments_outlined),
              StatTile(label: 'Reliability', value: '${a?.reliabilityPercent ?? 0}%', icon: Icons.star_half_rounded),
            ]))),
            const SizedBox(height: 16),
            Text('Incoming orders (${sp.incoming.length})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (sp.incoming.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Text('No incoming orders right now', style: TextStyle(color: AppColors.textMuted), textAlign: TextAlign.center))
            else
              ...sp.incoming.map((b) => IncomingOrderCard(broadcast: b, onAccept: () => sp.acceptOrder(b.orderId), onReject: () => sp.rejectOrder(b.orderId))),
          ]),
        );
      }),
    );
  }
}
