import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../theme/colors.dart';
import '../constants.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<DriverProvider>().loadEarnings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: Consumer<DriverProvider>(builder: (_, dp, __) {
        final e = dp.earnings;
        if (dp.isLoading) return const Center(child: CircularProgressIndicator());
        if (e == null) return const Center(child: Text('No earnings data'));
        return ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            _EarnCard(label: 'Today', amount: e.today.earnings, deliveries: e.today.deliveries),
            const SizedBox(width: 12),
            _EarnCard(label: 'This week', amount: e.thisWeek.earnings, deliveries: e.thisWeek.deliveries),
          ]),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All time', style: TextStyle(color: AppColors.textMuted)),
              Text('$appCurrencySymbol ${e.allTime.earnings}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Text('${e.allTime.deliveries} deliveries across ${e.allTime.batches} batches', style: const TextStyle(color: AppColors.textMuted)),
            ],
          ))),
        ]);
      }),
    );
  }
}

class _EarnCard extends StatelessWidget {
  const _EarnCard({required this.label, required this.amount, required this.deliveries});
  final String label;
  final int amount;
  final int deliveries;
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text('$appCurrencySymbol $amount', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text('$deliveries deliveries', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    ))));
  }
}
