import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../theme/colors.dart';

class ReliabilityScreen extends StatefulWidget {
  const ReliabilityScreen({super.key});
  @override
  State<ReliabilityScreen> createState() => _ReliabilityScreenState();
}

class _ReliabilityScreenState extends State<ReliabilityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ShopProvider>().loadAnalytics());
  }

  String _tierLabel(int p) => p >= 90 ? 'Gold' : p >= 70 ? 'Silver' : p >= 50 ? 'Bronze' : 'Needs Improvement';
  Color _tierColor(int p) => p >= 70 ? AppColors.accent : p >= 50 ? AppColors.primary : AppColors.error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reliability Score')),
      body: Consumer<ShopProvider>(builder: (_, sp, __) {
        final a = sp.analytics;
        if (sp.isLoading || a == null) return const Center(child: CircularProgressIndicator());
        final pct = a.reliabilityPercent;
        return ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
            const Text('Your Score', style: TextStyle(fontSize: 16)),
            Text('$pct%', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: _tierColor(pct).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24)),
              child: Text(_tierLabel(pct), style: TextStyle(color: _tierColor(pct), fontWeight: FontWeight.w600)),
            ),
          ]))),
          const SizedBox(height: 16),
          const Text('Score breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ListTile(leading: const Icon(Icons.check_circle, color: AppColors.success), title: const Text('Orders fulfilled'), trailing: Text('${a.orders.allTime - a.orders.cancelled}')),
          ListTile(leading: const Icon(Icons.cancel, color: AppColors.error), title: const Text('Cancelled after accept'), trailing: Text('${a.orders.cancelled}')),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('How it works', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Fulfilling orders: +2% per delivery. Cancelling after accept: -8%. Higher scores = more order broadcasts.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ]))),
        ]);
      }),
    );
  }
}
