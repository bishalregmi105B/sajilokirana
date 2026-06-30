import 'package:flutter/material.dart';

import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';

/// Vertical category tile: a 56×56 squircle image (or fallback icon) over a
/// centered caption label. See `docs/COMPONENT_SPEC.md` §5.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    this.imageProvider,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final ImageProvider? imageProvider;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: AppRadius.cardBorder,
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: imageProvider == null
                ? const Icon(
                    Icons.category_outlined,
                    color: AppColors.textMuted,
                  )
                : ClipRRect(
                    borderRadius: AppRadius.cardBorder,
                    child: Image(
                      image: imageProvider!,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
