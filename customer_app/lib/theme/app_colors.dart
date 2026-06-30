import 'package:flutter/material.dart';

/// SajiloKirana design-system color tokens.
///
/// This is the ONLY file in the app that may declare a `Color`.
/// Every other file pulls colors from here via `Theme.of(context)` or
/// `AppColors.<token>`. See `docs/AUDIT.md` §5 — the old app inlined
/// ~110 colors across 31 files; that must not return.
///
/// Palette: terracotta (primary) / charcoal (primaryDark) / gold (accent),
/// aligned to the investor deck.
class AppColors {
  AppColors._(); // prevent instantiation

  // ── Brand ────────────────────────────────────────────────────────────────
  /// `#A8442C` terracotta — primary buttons, active states, brand accents.
  static const Color primary = Color(0xFFA8442C);

  /// `#2B2D3D` charcoal — headers on dark surfaces, primary text.
  static const Color primaryDark = Color(0xFF2B2D3D);

  /// `#E8A33D` gold — highlights, badges, secondary CTAs.
  static const Color accent = Color(0xFFE8A33D);

  // ── Surfaces ─────────────────────────────────────────────────────────────
  /// `#FFFFFF` — backgrounds.
  static const Color surface = Color(0xFFFFFFFF);

  /// `#FBEEE8` — cards, subtle containers.
  static const Color surfaceTint = Color(0xFFFBEEE8);

  // ── Text ─────────────────────────────────────────────────────────────────
  /// Primary text (alias of charcoal for readability at call sites).
  static const Color textPrimary = Color(0xFF2B2D3D);

  /// `#6B6F7A` — secondary text, captions.
  static const Color textMuted = Color(0xFF6B6F7A);

  // ── Semantic ─────────────────────────────────────────────────────────────
  /// `#2E7D52` — order confirmed, delivered.
  static const Color success = Color(0xFF2E7D52);

  /// `#C0392B` — failures, out-of-stock flags.
  static const Color error = Color(0xFFC0392B);

  /// `#E8A33D` — low stock, delays (same value as accent; separate token
  /// because the *meaning* differs and may diverge later).
  static const Color warning = Color(0xFFE8A33D);

  // ── Derived helpers ──────────────────────────────────────────────────────
  /// Divider / hairline borders.
  static const Color border = Color(0xFFE7E5E2);

  /// Subtle background tint for scaffolds (warm off-white).
  static const Color scaffold = Color(0xFFFCFAF8);

  /// Soft elevation shadow color. Pair with `AppElevation.card`.
  static const Color shadow = Color(0x14000000); // black @ 8% alpha

  // ── Status colors for [OrderStatusBadge] ─────────────────────────────────
  /// Maps the backend order status string to a foreground color token.
  /// Kept here so status styling lives next to the palette it references.
  static Color forOrderStatus(String status) {
    switch (status) {
      case 'pending':
      case 'broadcasting':
        return warning;
      case 'shop_confirmed':
      case 'picked_up':
      case 'in_transit':
        return primary;
      case 'delivered':
        return success;
      case 'cancelled':
        return error;
      default:
        return textMuted;
    }
  }
}
