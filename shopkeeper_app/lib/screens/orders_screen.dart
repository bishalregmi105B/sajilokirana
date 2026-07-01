import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../theme/colors.dart';
import '../constants.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<ShopProvider>();
      sp.loadActiveOrders(); sp.loadOrderHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders'), bottom: TabBar(controller: _tabCtrl, tabs: const [
        Tab(text: 'Active'), Tab(text: 'History'),
      ], labelColor: AppColors.primary, indicatorColor: AppColors.primary)),
      body: Consumer<ShopProvider>(builder: (_, sp, __) {
        return TabBarView(controller: _tabCtrl, children: [
          sp.activeOrders.isEmpty
            ? const Center(child: Text('No active orders', style: TextStyle(color: AppColors.textMuted)))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: sp.activeOrders.length, itemBuilder: (_, i) {
                final o = sp.activeOrders[i];
                return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                  title: Text('Order #${o.id.substring(0, 8)}'), subtitle: Text(o.itemSummary),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$appCurrencySymbol ${o.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(o.status.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                  ]),
                ));
              }),
          sp.isLoading ? const Center(child: CircularProgressIndicator())
            : sp.orderHistory.isEmpty ? const Center(child: Text('No history', style: TextStyle(color: AppColors.textMuted)))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: sp.orderHistory.length, itemBuilder: (_, i) {
                final o = sp.orderHistory[i];
                final ok = o.status == 'delivered';
                return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                  leading: CircleAvatar(backgroundColor: (ok ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                    child: Icon(ok ? Icons.check_rounded : Icons.close_rounded, color: ok ? AppColors.success : AppColors.error)),
                  title: Text('Order #${o.id.substring(0, 8)}'), subtitle: Text(o.itemSummary),
                  trailing: Text('$appCurrencySymbol ${o.totalAmount.toStringAsFixed(0)}'),
                ));
              }),
        ]);
      }),
    );
  }
}
