import 'package:flutter/material.dart';

// APP COLOR PALETTE
// Satu tempat untuk semua warna aplikasi.
class AppColors {
  AppColors._(); // prevent instantiation

  // --- Primary ---
  static const Color primary = Color(0xFFF2C287);
  static const Color terracotta = Color(0xFFE67E5D);

  // --- Background ---
  static const Color backgroundLight = Color(0xFFFCF9F5);
  static const Color backgroundAlt = Color(0xFFFAF7F2);
  static const Color cardBg = Colors.white;

  // --- Border ---
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // --- Text ---
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMedium = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color textLabel = Color(0xFF334155);
  static const Color textOnPrimary = Color(0xFF292524);
  static const Color textNavDark = Color(0xFF1E293B);
  static const Color textSlate = Color(0xFF475569);

  // --- Accent / Status ---
  static const Color accentOrangeBg = Color(0xFFFFF7ED);
  static const Color accentOrangeBorder = Color(0xFFFFEDD5);
  static const Color accentOrangeText = Color(0xFFF97316);

  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);
  static const Color errorText = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFF7F1D1D);

  // --- Misc ---
  static const Color iconBgLight = Color(0xFFF1F5F9);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color checkboxBorder = Color(0xFFCBD5E1);
}

// APP THEME
// Gunakan AppTheme.light() di MaterialApp -> theme:
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.backgroundLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderColor),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return null;
        }),
        side: const BorderSide(color: AppColors.checkboxBorder),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }
}