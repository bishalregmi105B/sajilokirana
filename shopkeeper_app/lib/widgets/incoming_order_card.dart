import 'dart:async';
import 'package:flutter/material.dart';
import '../models/broadcast.dart';
import '../theme/colors.dart';
import '../constants.dart';

class IncomingOrderCard extends StatefulWidget {
  const IncomingOrderCard({super.key, required this.broadcast, required this.onAccept, required this.onReject});
  final IncomingBroadcast broadcast;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  @override
  State<IncomingOrderCard> createState() => _IncomingOrderCardState();
}

class _IncomingOrderCardState extends State<IncomingOrderCard> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final bt = DateTime.tryParse(widget.broadcast.broadcastAt) ?? DateTime.now();
    final elapsed = DateTime.now().difference(bt).inSeconds;
    _secondsLeft = (widget.broadcast.confirmWindowSeconds - elapsed).clamp(0, widget.broadcast.confirmWindowSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0) setState(() => _secondsLeft--);
      else _timer?.cancel();
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final order = widget.broadcast.order;
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(12), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Order #${widget.broadcast.orderId.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24)),
            child: Text('${_secondsLeft}s', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(order.itemSummary),
        Text('Total: $appCurrencySymbol ${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: _secondsLeft > 0 ? widget.onReject : null, child: const Text('Reject'))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(onPressed: _secondsLeft > 0 ? widget.onAccept : null, child: const Text('Accept'))),
        ]),
      ],
    )));
  }
}
