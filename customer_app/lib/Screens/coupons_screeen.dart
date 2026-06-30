import 'package:flutter/material.dart';

import 'package:ecom/constants.dart';
import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_button.dart';
import 'package:ecom/widgets/app_card.dart';
import 'package:ecom/widgets/app_text_field.dart';

class CouponsSelectionScreen extends StatefulWidget {
  const CouponsSelectionScreen({super.key});

  @override
  State<CouponsSelectionScreen> createState() => _CouponsSelectionScreenState();
}

class _CouponsSelectionScreenState extends State<CouponsSelectionScreen> {
  final _codeCtrl = TextEditingController();
  String? _appliedCode;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _apply(String code) {
    setState(() => _appliedCode = code.toUpperCase());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _codeCtrl,
                    hintText: 'Enter coupon code',
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: 'Apply',
                  onPressed: () {
                    if (_codeCtrl.text.trim().isEmpty) return;
                    _apply(_codeCtrl.text.trim());
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Best coupons for you',
                  style: AppTypography.headline),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: kDummyCoupons.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) {
                final coupon = kDummyCoupons[i];
                final code = coupon['couponCode'] as String;
                final isApplied = _appliedCode == code.toUpperCase();
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              coupon['headline'] as String,
                              style: AppTypography.bodyLarge,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppButton(
                            label: isApplied ? 'Applied' : 'Apply',
                            variant: isApplied
                                ? AppButtonVariant.secondary
                                : AppButtonVariant.primary,
                            onPressed: isApplied ? null : () => _apply(code),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceTint,
                          borderRadius: AppRadius.pillBorder,
                        ),
                        child: Text(
                          'Code: $code',
                          style: AppTypography.label
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...(coupon['dataPoints'] as List).map(
                        (pt) => Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('· '),
                              Expanded(
                                child: Text(pt as String,
                                    style: AppTypography.caption),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
