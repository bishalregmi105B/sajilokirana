import 'package:flutter/material.dart';
import '../models/batch.dart';
import '../theme/colors.dart';
import '../constants.dart';

class BatchCard extends StatelessWidget {
  const BatchCard({super.key, required this.batch, this.onStartDelivery});
  final Batch batch;
  final VoidCallback? onStartDelivery;

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Batch #${batch.id.substring(0, 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${batch.orders.length} orders', style: const TextStyle(color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 12),
        ...batch.orders.map((order) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.shop?.shopName ?? 'Shop', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(order.itemSummary, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Text('$appCurrencySymbol ${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ])),
          ]),
        )),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          icon: const Icon(Icons.navigation_rounded),
          label: const Text('Start Delivery'),
          onPressed: onStartDelivery,
        )),
      ]),
    ));
  }
}
