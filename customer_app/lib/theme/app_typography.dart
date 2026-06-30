import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// SajiloKirana typography.
///
/// Headings use **Lora** (serif — matches the brand's print identity),
/// body text uses **Inter**. No screen should call `TextStyle(fontSize:...)`
/// directly — pull a named style from here or from `Theme.of(context)`.
/// See `docs/AUDIT.md` §6 (the old app inlined ~18 TextStyles).
class AppTypography {
  AppTypography._();

  static const String _headingFamily = 'Lora';
  static const String _bodyFamily = 'Inter';

  // ── Display / headline (Lora) ────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.lora(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get displayMedium => GoogleFonts.lora(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get headline => GoogleFonts.lora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // ── Body (Inter) ─────────────────────────────────────────────────────────
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.45,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.4,
      );

  // ── UI text (Inter) ──────────────────────────────────────────────────────
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.surface,
        height: 1.2,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// Maps the named styles onto Material's [TextTheme] so screens can also
  /// reach them via `Theme.of(context).textTheme`.
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        headlineMedium: headline,
        titleMedium: bodyLarge,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: button,
        labelSmall: label,
      );

  /// Convenience for static family strings (unused import guard).
  static const families = (_headingFamily, _bodyFamily);
}
