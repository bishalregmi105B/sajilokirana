import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../theme/colors.dart';
import '../constants.dart';

class PayoutsScreen extends StatefulWidget {
  const PayoutsScreen({super.key});
  @override
  State<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends State<PayoutsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ShopProvider>().loadAnalytics());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payouts')),
      body: Consumer<ShopProvider>(builder: (_, sp, __) {
        final a = sp.analytics;
        if (sp.isLoading || a == null) return const Center(child: CircularProgressIndicator());
        return ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('This week', style: TextStyle(color: AppColors.textMuted)),
            Text('$appCurrencySymbol ${a.revenue.thisWeek.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text('${a.orders.thisWeek} orders', style: const TextStyle(color: AppColors.textMuted)),
          ]))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Today', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Text('$appCurrencySymbol ${a.revenue.today.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ])))),
            const SizedBox(width: 12),
            Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('All time', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Text('$appCurrencySymbol ${a.revenue.allTime.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ])))),
          ]),
        ]);
      }),
    );
  }
}
