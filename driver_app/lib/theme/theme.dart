import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.scaffold,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.surface,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.lora(
        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceTint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
    ),
  );
}
