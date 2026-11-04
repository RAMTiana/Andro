import 'package:flutter/material.dart';

/// Palette tirée de la vidéo « color design » :
/// Violet aubergine #4B0082 · Argenté #C0C0C0 · Doré #D4AF37
/// + neutres sombres teintés aubergine pour les fonds.
class AppColors {
  AppColors._();

  // --- Palette de la vidéo ---
  static const aubergine = Color(0xFF4B0082);
  static const silver = Color(0xFFC0C0C0);
  static const gold = Color(0xFFD4AF37);

  // --- Dérivés (même teinte, luminosité différente) ---
  static const aubergineLight = Color(0xFF7B3FB0); // accents sur fond sombre
  static const aubergineDeep = Color(0xFF2A0A4A); // fin de dégradé
  static const bg = Color(0xFF0E0716); // fond principal
  static const surface = Color(0xFF1A0F2A); // cartes
  static const surfaceHigh = Color(0xFF261840); // éléments surélevés
  static const outline = Color(0xFF3A2A55); // bordures fines

  // --- Statuts (budget) ---
  static const warning = Color(0xFFF0A23B);
  static const danger = Color(0xFFE5484D);
}

class AppTheme {
  AppTheme._();

  static const _radius = 20.0;

  static ThemeData get dark {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.gold,
      onPrimary: Color(0xFF1A1200),
      primaryContainer: AppColors.aubergine,
      onPrimaryContainer: Color(0xFFF3E9FF),
      secondary: AppColors.silver,
      onSecondary: Color(0xFF1A1A1A),
      secondaryContainer: AppColors.surfaceHigh,
      onSecondaryContainer: AppColors.silver,
      tertiary: AppColors.aubergineLight,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: AppColors.bg,
      onSurface: Color(0xFFF2EEF7),
      onSurfaceVariant: AppColors.silver,
      surfaceContainerLowest: AppColors.bg,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHigh,
      outline: AppColors.outline,
      outlineVariant: AppColors.outline,
    );
    return _build(scheme);
  }

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.aubergine,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFEBDDFA),
      onPrimaryContainer: Color(0xFF2A0A4A),
      secondary: Color(0xFF6B6B6B),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEDEAF2),
      onSecondaryContainer: Color(0xFF2B2B2B),
      tertiary: Color(0xFF9A7B1C), // doré foncé, lisible sur fond clair
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: Color(0xFFF7F5FA),
      onSurface: Color(0xFF1A1224),
      onSurfaceVariant: Color(0xFF5E5668),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Colors.white,
      surfaceContainer: Colors.white,
      surfaceContainerHigh: Color(0xFFEFEBF5),
      surfaceContainerHighest: Color(0xFFE7E1EF),
      outline: Color(0xFFD9D1E3),
      outlineVariant: Color(0xFFD9D1E3),
    );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;
    final base = ThemeData(colorScheme: cs, useMaterial3: true);
    final text = base.textTheme.apply(
      bodyColor: cs.onSurface,
      displayColor: cs.onSurface,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
      side: BorderSide(color: cs.outline),
    );

    return base.copyWith(
      scaffoldBackgroundColor: cs.surface,
      textTheme: text.copyWith(
        displayMedium: text.displayMedium
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1),
        headlineLarge: text.headlineLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(letterSpacing: -0.3),
      ),
      cardTheme: CardThemeData(
        color: cs.surfaceContainer,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: shape,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: cs.secondary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: cs.outline, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: cs.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        selectedColor: isDark ? AppColors.aubergine : cs.primaryContainer,
        side: BorderSide(color: cs.outline),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(color: cs.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor:
              isDark ? AppColors.aubergine : cs.primaryContainer,
          selectedForegroundColor: isDark ? AppColors.gold : cs.primary,
          side: BorderSide(color: cs.outline),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: cs.onSurface),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark ? AppColors.aubergine : cs.primaryContainer,
        labelTextStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.primary),
    );
  }
}