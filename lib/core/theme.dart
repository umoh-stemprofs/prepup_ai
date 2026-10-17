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

  // ---------------------------------------------------------------------------
  // Design tokens from `design/*/code.html`
  // ---------------------------------------------------------------------------
  //
  // Kept beside the brand colors so screens reference names instead of
  // repeating hex literals from the exports. `primary` above is the export's
  // `primary-container`; [primaryAction] is its darker `primary`.

  /// Solid fill for primary actions and selected subject chips.
  static const Color primaryAction = Color(0xFF004AC6);

  /// `primary-container` — selected two-up choice cards.
  static const Color primaryContainer = Color(0xFF2563EB);
  static const Color onPrimaryContainer = Color(0xFFEEEFFF);

  /// `primary-fixed` — subject chip and career icon tile.
  static const Color primaryFixed = Color(0xFFDBE1FF);
  static const Color onPrimaryFixed = Color(0xFF00174B);

  /// Brand green — badges and the save action.
  static const Color secondary = Color(0xFF006E2D);
  static const Color secondaryContainer = Color(0xFF7CF994);
  static const Color onSecondaryContainer = Color(0xFF007230);

  /// Amber — the "find jobs" action.
  static const Color tertiaryContainer = Color(0xFFA65900);
  static const Color onTertiaryContainer = Color(0xFFFFEDE1);

  /// Error containers as exported (#FFDAD6 / #93000A), plus the ring red.
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color errorRing = Color(0xFFBA1A1A);

  /// Surfaces and text.
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);
  static const Color surfaceVariant = Color(0xFFE1E3E4);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF434655);
  static const Color outline = Color(0xFF737686);

  /// Secondary on-color (white) for green buttons.
  static const Color onSecondary = Color(0xFFFFFFFF);

  /// On-primary — white text on the primary blue.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// On-primary-fixed — dark text on the primary-fixed light blue.
  static const Color onPrimaryFixedVariant = Color(0xFF003EA8);
}

// ---------------------------------------------------------------------------
// Shared bottom navigation bar for pushed screens.
// ---------------------------------------------------------------------------

/// The four bottom nav destinations used by [MainShell] and standalone
/// pushed screens.
const List<NavigationDestination> _bottomNavDestinations = [
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home, color: AppColors.primary),
    label: 'Home',
  ),
  NavigationDestination(
    icon: Icon(Icons.school_outlined),
    selectedIcon: Icon(Icons.school),
    label: 'Practice',
  ),
  NavigationDestination(
    icon: Icon(Icons.psychology_outlined),
    selectedIcon: Icon(Icons.psychology),
    label: 'AI Career',
  ),
  NavigationDestination(
    icon: Icon(Icons.person_outline),
    selectedIcon: Icon(Icons.person),
    label: 'Profile',
  ),
];

/// Standalone bottom navigation bar for use on pushed screens.
///
/// Use this on screens that are pushed on top of the shell but still
/// want the bottom nav visible (e.g. career helper, saved careers).
/// Pass [currentIndex] to highlight the active tab.
Widget bottomNavBar({int currentIndex = 0}) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      border: Border(
        top: BorderSide(
          color: AppColors.surfaceContainerHigh,
          width: 1,
        ),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (_) {},
        indicatorColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        destinations: _bottomNavDestinations,
      ),
    ),
  );
}

/// Shared dimensions.
// ---------------------------------------------------------------------------
// Shared app logo — used on login, register, and dashboard header.
// ---------------------------------------------------------------------------

/// Returns a logo image widget sized for the dashboard sticky header (36×36).
Widget appLogoDashboardHeader() {
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1a000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.cover,
        errorBuilder: (error, context, child) => const Icon(
          Icons.school_outlined,
          size: 22,
          color: AppColors.primary,
        ),
      ),
    ),
  );
}

/// Returns a logo image widget sized for the login/register page (96×96).
Widget appLogoPage() {
  return Container(
    width: 96,
    height: 96,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.cover,
        errorBuilder: (error, context, child) => const Icon(
          Icons.school_outlined,
          size: 46,
          color: AppColors.primary,
        ),
      ),
    ),
  );
}

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
    ).copyWith(surface: AppColors.background);

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
      textStyle: WidgetStatePropertyAll<TextStyle>(textTheme.labelLarge!),
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
          backgroundColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
          foregroundColor: const WidgetStatePropertyAll<Color>(
            AppColors.primary,
          ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
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
