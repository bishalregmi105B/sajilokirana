import 'package:flutter/material.dart';

import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';

/// A pill-shaped −/qty/+ stepper. Terracotta background, surface icons/text.
/// "−" disables at [min], "+" disables at [max]. See `docs/COMPONENT_SPEC.md` §5.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.qty,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
  });

  final int qty;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  bool get _decDisabled => qty <= min;
  bool get _incDisabled => qty >= max;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onTap: _decDisabled ? null : () => onChanged(qty - 1),
            disabled: _decDisabled,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              '$qty',
              style: AppTypography.label.copyWith(color: AppColors.surface),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onTap: _incDisabled ? null : () => onChanged(qty + 1),
            disabled: _incDisabled,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.disabled,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final Widget child = SizedBox(
      width: 28,
      height: 28,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillBorder,
        child: Icon(icon, size: 16, color: AppColors.surface),
      ),
    );
    return disabled ? Opacity(opacity: 0.4, child: child) : child;
  }
}
