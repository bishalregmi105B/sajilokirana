import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    // Auto-navigate to home after 5 seconds.
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 280,
                  child: Lottie.asset(
                    'Assets/cart_packing.json',
                    controller: _ctrl,
                    onLoaded: (comp) {
                      _ctrl
                        ..duration = comp.duration
                        ..repeat();
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Order Confirmed!',
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your order has been placed and the shop is being notified.',
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Redirecting in a moment…',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
