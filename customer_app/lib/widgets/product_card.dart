import 'package:flutter/material.dart';

import 'package:ecom/constants.dart' show appCurrencySymbol;
import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/quantity_stepper.dart';

/// A catalog product tile: image, name, unit, price (optional MRP
/// strikethrough), stock badge, and an Add / QuantityStepper control.
/// See `docs/COMPONENT_SPEC.md` §5.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    this.unit,
    this.mrp,
    this.imageProvider,
    this.isInStock = true,
    this.initialQty = 0,
    this.onAdd,
    this.onQtyChanged,
    this.onTap,
  });

  final String name;
  final double price;
  final String? unit;
  final double? mrp;
  final ImageProvider? imageProvider;
  final bool isInStock;
  final int initialQty;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onQtyChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardBorder,
          border: Border.all(color: AppColors.border),
          boxShadow: AppElevation.card(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: imageProvider == null
                  ? Container(
                      color: AppColors.surfaceTint,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.textMuted,
                      ),
                    )
                  : Image(image: imageProvider!, fit: BoxFit.cover),
            ),
            Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (unit != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(unit!, style: AppTypography.caption),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$appCurrencySymbol ${price.toStringAsFixed(0)}',
                        style: AppTypography.label,
                      ),
                      if (mrp != null && mrp! > price) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$appCurrencySymbol ${mrp!.toStringAsFixed(0)}',
                          style: AppTypography.caption.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (!isInStock)
                    const _OutOfStockChip()
                  else if (initialQty == 0)
                    _AddPill(onTap: onAdd)
                  else
                    QuantityStepper(
                      qty: initialQty,
                      onChanged: (q) => onQtyChanged?.call(q),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutOfStockChip extends StatelessWidget {
  const _OutOfStockChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: AppColors.error),
      ),
      child: Text(
        'Out of stock',
        style: AppTypography.caption.copyWith(color: AppColors.error),
      ),
    );
  }
}

class _AddPill extends StatelessWidget {
  const _AddPill({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.primary,
        borderRadius: AppRadius.pillBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pillBorder,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              'Add',
              style: AppTypography.label.copyWith(color: AppColors.surface),
            ),
          ),
        ),
      ),
    );
  }
}
