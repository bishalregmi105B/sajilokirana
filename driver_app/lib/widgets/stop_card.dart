import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum StopType { pickup, dropoff }

class StopCard extends StatelessWidget {
  const StopCard({super.key, required this.type, required this.title, required this.subtitle, required this.isDone, this.onConfirm});
  final StopType type;
  final String title;
  final String subtitle;
  final bool isDone;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final isPickup = type == StopType.pickup;
    final color = isPickup ? AppColors.primary : AppColors.success;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(isPickup ? Icons.storefront_outlined : Icons.home_outlined, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isPickup ? 'PICKUP' : 'DROP OFF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ])),
            if (isDone) const Icon(Icons.check_circle_rounded, color: AppColors.success),
          ]),
          if (!isDone && onConfirm != null) ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: onConfirm,
              child: Text(isPickup ? 'Confirm Pickup' : 'Confirm Delivery'),
            )),
          ],
        ],
      )),
    );
  }
}
