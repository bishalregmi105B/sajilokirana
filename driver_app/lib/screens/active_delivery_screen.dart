import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../theme/colors.dart';
import '../widgets/stop_card.dart';

class ActiveDeliveryScreen extends StatelessWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Delivery')),
      body: Consumer<DriverProvider>(builder: (_, dp, __) {
        final batch = dp.currentBatch;
        if (batch == null) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted),
              SizedBox(height: 16),
              Text('No active delivery', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
            ],
          ));
        }
        return Column(children: [
          // Map placeholder
          Container(
            height: 200,
            color: AppColors.surfaceTint,
            child: const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 48, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text('Live map with driver tracking', style: TextStyle(color: AppColors.textMuted)),
              ],
            )),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: batch.orders.length * 2, // pickup + dropoff per order
              itemBuilder: (ctx, i) {
                final orderIndex = i ~/ 2;
                final isPickup = i % 2 == 0;
                final order = batch.orders[orderIndex];
                final isPickedUp = order.status == 'picked_up' || order.status == 'in_transit' || order.status == 'delivered';
                final isDelivered = order.status == 'delivered';

                if (isPickup) {
                  return StopCard(
                    type: StopType.pickup,
                    title: order.shop?.shopName ?? 'Shop',
                    subtitle: order.itemSummary,
                    isDone: isPickedUp,
                    onConfirm: isPickedUp ? null : () => dp.confirmPickup(order.id),
                  );
                } else {
                  final addr = order.deliveryAddress;
                  return StopCard(
                    type: StopType.dropoff,
                    title: addr?['label'] as String? ?? 'Customer',
                    subtitle: addr?['line1'] as String? ?? '',
                    isDone: isDelivered,
                    onConfirm: (!isPickedUp || isDelivered) ? null : () => dp.confirmDelivery(order.id),
                  );
                }
              },
            ),
          ),
        ]);
      }),
    );
  }
}
