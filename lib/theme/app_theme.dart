import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color pinkPrimary = Color(0xFFFF4D8D);
  static const Color pinkDark = Color(0xFFD6316B);
  static const Color pinkLight = Color(0xFFFFB6CE);
  static const Color pinkPale = Color(0xFFFFE3EE);

  // Secondary Palette
  static const Color greenPrimary = Color(0xFF22B573);
  static const Color greenDark = Color(0xFF178A57);
  static const Color greenLight = Color(0xFF7BD9AE);
  static const Color greenPale = Color(0xFFDAF6E9);

  // Neutral & Semantic Colors
  static const Color inkText = Color(0xFF372E3D);
  static const Color graySecondary = Color(0xFF7A7285);
  static const Color grayLine = Color(0xFFEDE9F0);
  static const Color grayBg = Color(0xFFF8F9FA);
  static const Color white = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF22B573);
  static const Color warning = Color(0xFFF2B705);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF3B82F6);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.white,
      primaryColor: AppColors.pinkPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.pinkPrimary,
        secondary: AppColors.greenPrimary,
        surface: AppColors.white,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.inkText,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.inkText),
        titleTextStyle: TextStyle(
          color: AppColors.inkText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pinkPrimary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.pinkPrimary,
          side: const BorderSide(color: AppColors.pinkPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grayBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.grayLine, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.pinkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: const TextStyle(color: AppColors.graySecondary, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.grayLine,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
