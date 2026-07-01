import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../theme/colors.dart';
import '../constants.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<DriverProvider>().loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batch History')),
      body: Consumer<DriverProvider>(builder: (_, dp, __) {
        if (dp.isLoading) return const Center(child: CircularProgressIndicator());
        if (dp.history.isEmpty) return const Center(child: Text('No completed batches yet'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dp.history.length,
          itemBuilder: (ctx, i) {
            final batch = dp.history[i];
            final totalEarned = batch.orders.fold<double>(0, (s, o) => s + o.totalAmount) * 0.15;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.success.withValues(alpha: 0.12),
                  child: const Icon(Icons.check_rounded, color: AppColors.success),
                ),
                title: Text('Batch #${batch.id.substring(0, 6).toUpperCase()}'),
                subtitle: Text('${batch.orders.length} orders'),
                trailing: Text('$appCurrencySymbol ${totalEarned.round()}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      }),
    );
  }
}
