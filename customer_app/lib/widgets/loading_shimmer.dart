import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';

/// A shimmer skeleton loader (Part A.2.4 — skeleton, **not** a spinner).
/// Wraps any [child] in an animated [Shimmer.fromColors] that uses
/// [AppColors.surfaceTint] as the base and [AppColors.surface] as the
/// highlight, so skeletons always stay on-palette. See `docs/COMPONENT_SPEC.md`
/// §5.
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceTint,
      highlightColor: AppColors.surface,
      period: const Duration(milliseconds: 1000),
      child: child,
    );
  }

  /// A skeleton list: [itemCount] rows, each with a leading 48×48 squircle
  /// placeholder and two shimmering lines.
  static Widget list({int itemCount = 6}) {
    return LoadingShimmer(
      child: ListView.builder(
        itemCount: itemCount,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemBuilder: (BuildContext context, int index) {
          return const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: _SkeletonRow(),
          );
        },
      ),
    );
  }

  /// A skeleton grid that mimics [ProductCard]: an image block plus two text
  /// lines per cell.
  static Widget grid({int crossAxisCount = 2}) {
    final int itemCount = crossAxisCount * 4;
    return LoadingShimmer(
      child: GridView.builder(
        itemCount: itemCount,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (BuildContext context, int index) {
          return const _SkeletonProductCard();
        },
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBorder,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: AppRadius.cardBorder,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _SkeletonLine(widthFactor: 0.9),
                SizedBox(height: AppSpacing.sm),
                _SkeletonLine(widthFactor: 0.6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonProductCard extends StatelessWidget {
  const _SkeletonProductCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: AppRadius.cardBorder,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _SkeletonLine(widthFactor: 0.9),
          const SizedBox(height: AppSpacing.sm),
          const _SkeletonLine(widthFactor: 0.5),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: AppSpacing.md,
        decoration: const BoxDecoration(
          color: AppColors.surfaceTint,
          borderRadius: AppRadius.cardBorder,
        ),
      ),
    );
  }
}
