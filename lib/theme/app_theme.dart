import 'package:flutter/material.dart';

class AppColors {
  static const Color oceanBlue = Color(0xFF0875E1);
  static const Color aqua = Color(0xFF20B8F5);
  static const Color aquaLight = Color(0xFFBDEBFF);
  static const Color aquaPale = Color(0xFFDDF4FF);
  static const Color aquaOverlay = Color(0x3320B8F5);
  static const Color deepNavy = Color(0xFF142C56);

  static const Color white = Color(0xFFFFFFFF);
  static const Color graySecondary = Color(0xB3142C56);
  static const Color grayLine = Color(0xFFDFE7F0);
  static const Color grayBg = Color(0xFFF6F8FC);

  static const Color success = Color(0xFF15803D);
  static const Color successDark = Color(0xFF14532D);
  static const Color successLight = Color(0xFF86EFAC);
  static const Color successPale = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFB45309);
  static const Color warningDark = Color(0xFF854D0E);
  static const Color warningPale = Color(0xFFFFF7D6);
  static const Color error = Color(0xFFB42318);
  static const Color errorPale = Color(0xFFFEE4E2);
  static const Color info = oceanBlue;

  static const Color listingSale = oceanBlue;
  static const Color listingExchange = Color(0xFF5B21B6);
  static const Color listingExchangePale = Color(0xFFF3E8FF);
  static const Color listingDonate = Color(0xFF064E3B);
}

class AppTheme {
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.oceanBlue,
      onPrimary: AppColors.white,
      secondary: AppColors.aqua,
      onSecondary: AppColors.deepNavy,
      tertiary: AppColors.listingExchange,
      onTertiary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.deepNavy,
      surfaceContainerHighest: AppColors.grayBg,
      outline: AppColors.grayLine,
      error: AppColors.error,
      onError: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primaryColor: AppColors.oceanBlue,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: 'Roboto',
      textTheme: Typography.material2021().black.apply(
        fontFamily: 'Roboto',
        bodyColor: AppColors.deepNavy,
        displayColor: AppColors.deepNavy,
      ),
      iconTheme: const IconThemeData(color: AppColors.deepNavy),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.deepNavy,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.deepNavy),
        titleTextStyle: TextStyle(
          color: AppColors.deepNavy,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.oceanBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.oceanBlue,
          foregroundColor: AppColors.white,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.oceanBlue,
          side: const BorderSide(color: AppColors.oceanBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.oceanBlue,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grayBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
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
          borderSide: const BorderSide(color: AppColors.oceanBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: const TextStyle(
          color: AppColors.graySecondary,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(color: AppColors.oceanBlue),
        prefixIconColor: AppColors.deepNavy,
        suffixIconColor: AppColors.deepNavy,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.aquaPale,
        labelStyle: const TextStyle(color: AppColors.deepNavy),
        secondaryLabelStyle: const TextStyle(color: AppColors.deepNavy),
        side: const BorderSide(color: AppColors.grayLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.aqua,
        inactiveTrackColor: AppColors.aquaPale,
        thumbColor: AppColors.oceanBlue,
        overlayColor: AppColors.aquaOverlay,
        valueIndicatorColor: AppColors.deepNavy,
        valueIndicatorTextStyle: TextStyle(color: AppColors.white),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.deepNavy
              : AppColors.graySecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.aqua
              : AppColors.grayLine;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.aqua
              : AppColors.white;
        }),
        checkColor: WidgetStateProperty.all(AppColors.deepNavy),
        side: const BorderSide(color: AppColors.graySecondary),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.oceanBlue,
        unselectedLabelColor: AppColors.graySecondary,
        indicatorColor: AppColors.aqua,
        dividerColor: AppColors.grayLine,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.aquaPale,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.oceanBlue
                : AppColors.graySecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.oceanBlue
                : AppColors.graySecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.bold
                : FontWeight.normal,
          );
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.oceanBlue,
        unselectedItemColor: AppColors.graySecondary,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.deepNavy,
        contentTextStyle: TextStyle(color: AppColors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.white,
        titleTextStyle: TextStyle(
          color: AppColors.deepNavy,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(color: AppColors.deepNavy, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        modalBackgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 1.5,
        shadowColor: AppColors.deepNavy.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.grayLine,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.oceanBlue,
        linearTrackColor: AppColors.aquaPale,
        circularTrackColor: AppColors.aquaPale,
      ),
    );
  }
}
