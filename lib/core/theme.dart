/// PrepUp AI — Material 3 theme (Phase 02).
///
/// Uses the default system Roboto font (no bundled font assets), extra-large
/// exam-readable typography, and massive touch targets.
library;

import 'package:flutter/material.dart';

/// Brand + semantic colors.
class AppColors {
  AppColors._();

  /// Primary — Royal Blue.
  static const Color primary = Color(0xFF2563EB);

  /// Success — Green.
  static const Color success = Color(0xFF16A34A);

  /// Error — Red.
  static const Color error = Color(0xFFDC2626);

  /// App background.
  static const Color background = Color(0xFFF8F9FA);

  /// Default text color.
  static const Color textPrimary = Color(0xFF111111);

  static const Color white = Color(0xFFFFFFFF);
}

/// Shared dimensions.
class AppDimensions {
  AppDimensions._();

  /// Massive button height.
  static const double buttonHeight = 60;

  /// Button corner radius.
  static const double buttonRadius = 16;

  /// Card corner radius.
  static const double cardRadius = 16;
}

class AppTheme {
  AppTheme._();

  /// Light theme used by [MaterialApp].
  static ThemeData get light {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      error: AppColors.error,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppColors.background,
    );

    // Extra-large typography: titles 24px+ ExtraBold, body/questions 18-20px
    // Bold, all in #111111. Font family intentionally omitted → system Roboto.
    const TextTheme textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.2,
      ),
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.35,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.35,
      ),
      // Body / question text: 18–20px Bold.
      bodyLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );

    final ButtonStyle elevatedButtonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size.fromHeight(AppDimensions.buttonHeight),
      ),
      maximumSize: const WidgetStatePropertyAll<Size>(
        Size.fromHeight(AppDimensions.buttonHeight),
      ),
      backgroundColor: WidgetStatePropertyAll<Color>(AppColors.primary),
      foregroundColor: const WidgetStatePropertyAll<Color>(AppColors.white),
      elevation: const WidgetStatePropertyAll<double>(0),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
        ),
      ),
      textStyle: WidgetStatePropertyAll<TextStyle>(
        textTheme.labelLarge!,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: null, // default system Roboto
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.headlineSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
      filledButtonTheme: FilledButtonThemeData(style: elevatedButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: elevatedButtonStyle.copyWith(
          backgroundColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          foregroundColor: const WidgetStatePropertyAll<Color>(AppColors.primary),
          side: const WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
      ),
    );
  }
}
