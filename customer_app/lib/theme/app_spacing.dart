import 'package:flutter/material.dart';

import 'app_colors.dart' show AppColors;

/// SajiloKirana spacing & shape scale.
///
/// The old app used ad-hoc values per call site (`8.0`, `10.0`, `15`, `5`…).
/// Part A.1 mandates a fixed 4/8/12/16/24/32 scale and corner radii of 12
/// (cards) / 24 (pills). Import `AppSpacing` / `AppRadius` everywhere instead
/// of literal numbers.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Common symmetric page padding (horizontal: 16).
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(
    horizontal: lg,
  );

  /// Full page padding (all: 16).
  static const EdgeInsets page = EdgeInsets.all(lg);

  /// Card internal padding (all: 12).
  static const EdgeInsets card = EdgeInsets.all(md);
}

/// Corner radii — 12 for cards/containers, 24 for buttons & pills.
class AppRadius {
  AppRadius._();

  static const double card = 12;
  static const double pill = 24;

  static const BorderRadius cardBorder = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius pillBorder = BorderRadius.all(
    Radius.circular(pill),
  );
}

/// Soft shadows only — `blurRadius: 8, opacity: 0.08`, never hard drop shadows.
class AppElevation {
  AppElevation._();

  /// Single soft shadow for cards / sticky bars.
  static List<BoxShadow> card(BuildContext context) => const [
    BoxShadow(
      color: AppColors.shadow,
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
}