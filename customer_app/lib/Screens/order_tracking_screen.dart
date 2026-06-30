import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ecom/Services/Providers/orders.provider.dart';
import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_card.dart';
import 'package:ecom/widgets/order_status_badge.dart';

/// Real-time order tracking.
/// Route: /order/track   Arguments: orderId (String)
class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, this.orderId});
  final String? orderId;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  AppOrder? _order;
  bool _isLoading = true;
  Timer? _pollTimer;
  Timer? _etaTimer;
  int _etaSeconds = 0;
  bool _delivered = false;

  String? get _orderId =>
      widget.orderId ?? ModalRoute.of(context)?.settings.arguments as String?;

  static const _pollInterval = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = _orderId;
    if (id == null) return;
    try {
      final order = await context.read<OrdersProvider>().fetchOne(id);
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
        if (order != null) {
          _etaSeconds = order.etaSeconds ?? 0;
          _delivered = order.status == 'delivered';
        }
      });
      if (!_delivered) {
        _startEtaCountdown();
        _startPolling();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startEtaCountdown() {
    _etaTimer?.cancel();
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_etaSeconds > 0) {
        setState(() => _etaSeconds--);
      } else {
        _etaTimer?.cancel();
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _etaTimer?.cancel();
    super.dispose();
  }

  String get _etaLabel {
    if (_etaSeconds <= 0) return 'Arriving soon';
    final m = _etaSeconds ~/ 60;
    final s = _etaSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  static const _statusSteps = [
    ('pending', 'Order placed', Icons.receipt_outlined),
    ('shop_confirmed', 'Shop accepted', Icons.store_outlined),
    ('picked_up', 'Picked up', Icons.electric_bike_rounded),
    ('in_transit', 'On the way', Icons.navigation_outlined),
    ('delivered', 'Delivered', Icons.check_circle_outline_rounded),
  ];

  int _stepIndex(String status) {
    switch (status) {
      case 'pending': return 0;
      case 'broadcasting': return 0;
      case 'shop_confirmed': return 1;
      case 'picked_up': return 2;
      case 'in_transit': return 3;
      case 'delivered': return 4;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : Column(
                  children: [
                    // ── ETA banner ─────────────────────────────────────────
                    if (!_delivered)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        color: AppColors.primary,
                        child: Column(
                          children: [
                            Text(
                              _etaLabel,
                              style: AppTypography.displayMedium
                                  .copyWith(color: AppColors.surface),
                            ),
                            Text(
                              'Estimated time of arrival',
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.surface.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                    // ── Status timeline ────────────────────────────────────
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          AppCard(
                            child: Column(
                              children: List.generate(_statusSteps.length, (i) {
                                final step = _statusSteps[i];
                                final currentIdx = _stepIndex(_order!.status);
                                final done = i <= currentIdx;
                                final active = i == currentIdx;
                                return Row(
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: done
                                                ? AppColors.primary
                                                : AppColors.border,
                                          ),
                                          child: Icon(
                                            step.$3,
                                            size: 16,
                                            color: done
                                                ? AppColors.surface
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                        if (i < _statusSteps.length - 1)
                                          Container(
                                            width: 2,
                                            height: 32,
                                            color: done
                                                ? AppColors.primary
                                                : AppColors.border,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Text(
                                      step.$2,
                                      style: active
                                          ? AppTypography.bodyLarge
                                          : AppTypography.body.copyWith(
                                              color: done
                                                  ? AppColors.primaryDark
                                                  : AppColors.textMuted,
                                            ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppCard(
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    color: AppColors.textMuted),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Order ID: ${_order!.id.substring(0, 8)}…',
                                    style: AppTypography.caption,
                                  ),
                                ),
                                OrderStatusBadge(status: _order!.status),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
