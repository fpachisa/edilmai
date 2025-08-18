import 'package:flutter/material.dart';

/// New application theme derived from sample-theme.jpg palette.
/// Applied behind the feature flag `kNewThemeEnabled` (see config.dart).
class NewAppTheme {
  // Brand
  static const Color _brandPrimary = Color(0xFF5BA843);
  static const Color _brandSecondary = Color(0xFF3B969D);
  static const Color _brandTertiary = Color(0xFF6C38B8);

  // Neutrals
  static const Color _neutral900 = Color(0xFF212227);
  static const Color _neutral800 = Color(0xFF343A45);
  static const Color _neutral700 = Color(0xFF505765);
  static const Color _neutral600 = Color(0xFF6E7583);
  static const Color _neutral100 = Color(0xFFEFF1F3);

  // Light scheme
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceVariant = Color(0xFFEFF2F6);
  static const Color _onLight = Color(0xFF0F1115);

  // Dark scheme
  static const Color _darkBackground = Color(0xFF121316);
  static const Color _darkSurface = Color(0xFF17181D);
  static const Color _darkSurfaceVariant = Color(0xFF1F2026);
  static const Color _onDark = Color(0xFFEDEFF3);

  // Semantic light
  static const Color _lightError = Color(0xFFE6662A);
  static const Color _lightWarning = Color(0xFFDBB10F);
  static const Color _lightSuccess = Color(0xFF5BA843);

  // Semantic dark
  static const Color _darkError = Color(0xFFFF8A50);
  static const Color _darkWarning = Color(0xFFFFD34D);
  static const Color _darkSuccess = Color(0xFF88E071);

  static ThemeData light() {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _brandPrimary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCF2D5),
      onPrimaryContainer: Color(0xFF163312),
      secondary: _brandSecondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD2EEF0),
      onSecondaryContainer: Color(0xFF0E2B2D),
      tertiary: _brandTertiary,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE6DAF9),
      onTertiaryContainer: Color(0xFF210E3A),
      error: _lightError,
      onError: Colors.white,
      errorContainer: Color(0xFFFFE2D6),
      onErrorContainer: Color(0xFF3B0B00),
      background: _lightBackground,
      onBackground: _onLight,
      surface: _lightSurface,
      onSurface: _onLight,
      surfaceVariant: _lightSurfaceVariant,
      onSurfaceVariant: _neutral700,
      outline: Color(0xFFA8ADB7),
      outlineVariant: Color(0xFFD4D8E0),
      shadow: Colors.black12,
      scrim: Colors.black54,
      inverseSurface: _neutral900,
      onInverseSurface: Colors.white,
      inversePrimary: _brandPrimary,
    );

    return _themeFromScheme(scheme, isDark: false);
  }

  static ThemeData dark() {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF77D25E),
      onPrimary: Color(0xFF0F1A0D),
      primaryContainer: Color(0xFF23451C),
      onPrimaryContainer: Color(0xFFB3F2A4),
      secondary: Color(0xFF5BC8CF),
      onSecondary: Color(0xFF0B1A1B),
      secondaryContainer: Color(0xFF12383B),
      onSecondaryContainer: Color(0xFFBEECEF),
      tertiary: Color(0xFFB28AF0),
      onTertiary: Color(0xFF1A1030),
      tertiaryContainer: Color(0xFF2B1B54),
      onTertiaryContainer: Color(0xFFE7DBFF),
      error: _darkError,
      onError: Color(0xFF230A02),
      errorContainer: Color(0xFF4A1A06),
      onErrorContainer: Color(0xFFFFD6C2),
      background: _darkBackground,
      onBackground: _onDark,
      surface: _darkSurface,
      onSurface: _onDark,
      surfaceVariant: _darkSurfaceVariant,
      onSurfaceVariant: Color(0xFFC7CBD3),
      outline: Color(0xFF505765),
      outlineVariant: Color(0xFF2A2C33),
      shadow: Colors.black54,
      scrim: Colors.black87,
      inverseSurface: _neutral100,
      onInverseSurface: _neutral900,
      inversePrimary: _brandPrimary,
    );

    return _themeFromScheme(scheme, isDark: true);
  }

  static ThemeData _themeFromScheme(ColorScheme scheme, {required bool isDark}) {
    final base = ThemeData(useMaterial3: true, brightness: scheme.brightness, colorScheme: scheme);
    final onText = scheme.onSurface;
    return base.copyWith(
      scaffoldBackgroundColor: scheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: onText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceVariant : const Color(0xFFF6F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
      cardTheme: CardThemeData(
        color: isDark ? scheme.surface : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        surfaceTintColor: scheme.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? scheme.surface : _neutral900,
        contentTextStyle: TextStyle(color: isDark ? scheme.onSurface : Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
