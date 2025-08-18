import 'package:flutter/material.dart';

/// Enhanced Design Tokens for PSLE AI Tutor
/// 
/// Provides consistent colors, typography, spacing, and timing
/// across the entire application with mathematical subject theming.
class DesignTokens {
  
  // ============ CORE COLORS ============
  
  /// Primary brand colors with tech gaming theme (Orange-Cyan from sample)
  static const Color primaryTechOrange = Color(0xFFFF6B35);
  static const Color primaryTechOrangeLight = Color(0xFFFF8A5C);
  static const Color primaryTechOrangeDark = Color(0xFFE55A2B);
  
  /// Accent colors with cyan tech theme
  static const Color accentTechCyan = Color(0xFF00B4D8);
  static const Color accentTechCyanLight = Color(0xFF33C3E0);
  static const Color accentTechCyanDark = Color(0xFF0081A7);
  
  /// Legacy support - map to new colors
  static const Color primaryMagic = Color(0xFFFF6B35);        // Orange
  static const Color primaryMagicLight = Color(0xFFFF8A5C);   // Light orange
  static const Color primaryMagicDark = Color(0xFFE55A2B);    // Dark orange
  
  /// Feedback colors with tech gaming effects
  static const Color successGlow = Color(0xFF00E676);
  static const Color successGlowLight = Color(0xFF66FFA6);
  static const Color successGlowDark = Color(0xFF00C853);
  
  static const Color warningAura = Color(0xFFFFAB00);
  static const Color warningAuraLight = Color(0xFFFFCC66);
  static const Color warningAuraDark = Color(0xFFCC8900);
  
  static const Color errorPulse = Color(0xFFFF5252);
  static const Color errorPulseLight = Color(0xFFFF8A80);
  static const Color errorPulseDark = Color(0xFFD32F2F);
  
  /// Neutral colors for tech dark theme (based on sample)
  static const Color neutralDark = Color(0xFF2C3E50);         // Dark gray from sample
  static const Color neutralMedium = Color(0xFF34495E);       // Medium gray tech
  static const Color neutralLight = Color(0xFF455A64);        // Light gray tech
  static const Color neutralSurface = Color(0xFF37474F);      // Surface gray tech
  
  // ============ TECH GAMING SUBJECT COLORS ============
  
  /// Each mathematical subject uses the orange-cyan tech gaming spectrum
  /// Designed for modern digital appeal and high visual impact
  
  // 🟠 ALGEBRA TECH - Primary orange with gaming vibes
  static const Color algebraTechOrange = Color(0xFFFF6B35);
  static const Color algebraTechOrangeLight = Color(0xFFFF8A5C);
  static const Color algebraTechOrangeDark = Color(0xFFE55A2B);
  static const Color algebraTechOrangeGlow = Color(0xFFFFB399);
  
  // Legacy support
  static const Color algebraMystic = Color(0xFFFF6B35);
  static const Color algebraMysticLight = Color(0xFFFF8A5C);
  static const Color algebraMysticDark = Color(0xFFE55A2B);
  static const Color algebraMysticGlow = Color(0xFFFFB399);
  
  // 🔵 FRACTIONS CYBER - Primary cyan with tech appeal
  static const Color fractionCyberBlue = Color(0xFF00B4D8);
  static const Color fractionCyberBlueLight = Color(0xFF33C3E0);
  static const Color fractionCyberBlueDark = Color(0xFF0081A7);
  static const Color fractionCyberBlueGlow = Color(0xFF66D9EF);
  
  // Legacy support
  static const Color fractionForest = Color(0xFF00B4D8);
  static const Color fractionForestLight = Color(0xFF33C3E0);
  static const Color fractionForestDark = Color(0xFF0081A7);
  static const Color fractionForestGlow = Color(0xFF66D9EF);
  
  // 🟠 PERCENTAGE TECH - Light orange tech variant
  static const Color percentageTechOrange = Color(0xFFFF8A5C);
  static const Color percentageTechOrangeLight = Color(0xFFFFB399);
  static const Color percentageTechOrangeDark = Color(0xFFE55A2B);
  static const Color percentageTechOrangeGlow = Color(0xFFFFCCB3);
  
  // Legacy support
  static const Color percentagePlanet = Color(0xFFFF8A5C);
  static const Color percentagePlanetLight = Color(0xFFFFB399);
  static const Color percentagePlanetDark = Color(0xFFE55A2B);
  static const Color percentagePlanetGlow = Color(0xFFFFCCB3);
  
  // 🔵 SPEED CYBER - Medium cyan for dynamic movement
  static const Color speedCyberBlue = Color(0xFF0081A7);
  static const Color speedCyberBlueLight = Color(0xFF33A4C7);
  static const Color speedCyberBlueDark = Color(0xFF005577);
  static const Color speedCyberBlueGlow = Color(0xFF66B8D1);
  
  // Legacy support
  static const Color speedStorm = Color(0xFF0081A7);
  static const Color speedStormLight = Color(0xFF33A4C7);
  static const Color speedStormDark = Color(0xFF005577);
  static const Color speedStormGlow = Color(0xFF66B8D1);
  
  // 🔵 RATIO TECH - Light cyan for ratios
  static const Color ratioTechCyan = Color(0xFF33C3E0);
  static const Color ratioTechCyanLight = Color(0xFF66D3E7);
  static const Color ratioTechCyanDark = Color(0xFF00B4D8);
  static const Color ratioTechCyanGlow = Color(0xFF99E3ED);
  
  // Legacy support
  static const Color ratioRealm = Color(0xFF33C3E0);
  static const Color ratioRealmLight = Color(0xFF66D3E7);
  static const Color ratioRealmDark = Color(0xFF00B4D8);
  static const Color ratioRealmGlow = Color(0xFF99E3ED);
  
  // 🟠 GEOMETRY TECH - Coral orange for geometry
  static const Color geometryTechCoral = Color(0xFFFF7F66);
  static const Color geometryTechCoralLight = Color(0xFFFF9980);
  static const Color geometryTechCoralDark = Color(0xFFFF5A3D);
  static const Color geometryTechCoralGlow = Color(0xFFFFB3A6);
  
  // Legacy support
  static const Color geometryGalaxy = Color(0xFFFF7F66);
  static const Color geometryGalaxyLight = Color(0xFFFF9980);
  static const Color geometryGalaxyDark = Color(0xFFFF5A3D);
  static const Color geometryGalaxyGlow = Color(0xFFFFB3A6);
  
  // 🔵 STATISTICS TECH - Deep cyan navy for data
  static const Color statisticsTechNavy = Color(0xFF023047);
  static const Color statisticsTechNavyLight = Color(0xFF034561);
  static const Color statisticsTechNavyDark = Color(0xFF011A2D);
  static const Color statisticsTechNavyGlow = Color(0xFF0B5A7B);
  
  // Legacy support
  static const Color statisticsSpace = Color(0xFF023047);
  static const Color statisticsSpaceLight = Color(0xFF034561);
  static const Color statisticsSpaceDark = Color(0xFF011A2D);
  static const Color statisticsSpaceGlow = Color(0xFF0B5A7B);
  
  /// Get subject color by key (palette-based distinct hues)
  static Color getSubjectColor(String subjectKey) {
    switch (subjectKey.toLowerCase()) {
      case 'algebra': return const Color(0xFF5BA843);      // green
      case 'fractions': return const Color(0xFF3B969D);    // teal
      case 'geometry': return const Color(0xFF6C38B8);     // purple
      case 'speed': return const Color(0xFFE6662A);        // orange
      case 'ratio': return const Color(0xFF9CB027);        // yellow-green
      case 'percentage': return const Color(0xFFDBB10F);   // gold
      case 'statistics': return const Color(0xFFA24578);   // magenta
      case 'measurement': return _lighten(const Color(0xFF3B969D), 0.25); // light teal
      case 'data-analysis': return const Color(0xFF5BC8CF); // bright teal
      default: return const Color(0xFF5BA843);
    }
  }
  
  /// Get subject light variant
  static Color getSubjectColorLight(String subjectKey) {
    final base = getSubjectColor(subjectKey);
    return _lighten(base, 0.22);
  }
  
  /// Get subject dark variant
  static Color getSubjectColorDark(String subjectKey) {
    final base = getSubjectColor(subjectKey);
    return _darken(base, 0.18);
  }
  
  /// Get subject glow variant for magical effects
  static Color getSubjectColorGlow(String subjectKey) {
    final base = getSubjectColor(subjectKey);
    return _blendWithWhite(base, 0.45);
  }
  
  /// Get magical gradient that makes topics come alive
  static LinearGradient getMagicalSubjectGradient(String subjectKey) {
    final base = getSubjectColor(subjectKey);
    final glow = getSubjectColorGlow(subjectKey);
    final light = getSubjectColorLight(subjectKey);
    return LinearGradient(
      colors: [base, glow, light],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.5, 1.0],
    );
  }
  
  // ============ TYPOGRAPHY SCALE ============
  
  /// Hero text for main titles and important callouts
  static const TextStyle heroTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.5,
  );
  
  /// Section titles for major UI areas
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );
  
  /// Subtitle for secondary information
  static const TextStyle subtitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  /// Problem text for mathematical questions
  static const TextStyle problemText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  /// Body text for general content
  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  /// Caption text for small labels and hints
  static const TextStyle captionText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  /// Button text styling
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  // ============ SPACING SYSTEM ============
  
  /// Extra small spacing for tight layouts
  static const double spaceXS = 4;
  /// Small spacing for related elements
  static const double spaceSM = 8;
  /// Medium spacing for standard layouts
  static const double spaceMD = 16;
  /// Large spacing for section separation
  static const double spaceLG = 24;
  /// Extra large spacing for major sections
  static const double spaceXL = 32;
  /// Extra extra large spacing for page-level separation
  static const double spaceXXL = 48;
  
  // ============ BORDER RADIUS ============
  
  /// Small radius for buttons and chips
  static const double radiusSM = 8;
  /// Medium radius for cards and containers
  static const double radiusMD = 16;
  /// Large radius for major UI elements
  static const double radiusLG = 24;
  /// Extra large radius for hero elements
  static const double radiusXL = 32;
  
  // ============ ANIMATION DURATIONS ============
  
  /// Quick interactions and micro-feedback
  static const Duration quickSnap = Duration(milliseconds: 150);
  /// Standard UI transitions
  static const Duration smoothFlow = Duration(milliseconds: 300);
  /// Attention-grabbing reveals
  static const Duration dramaticReveal = Duration(milliseconds: 600);
  /// Celebration and achievement animations
  static const Duration celebration = Duration(milliseconds: 1200);
  
  // ============ ELEVATION LEVELS ============
  
  /// Card elevation
  static const double elevationCard = 4;
  /// Modal and dialog elevation
  static const double elevationModal = 8;
  /// Floating action button elevation
  static const double elevationFAB = 6;
  /// App bar elevation
  static const double elevationAppBar = 2;
  
  // ============ GRADIENTS ============
  
  /// Primary brand gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryMagic, primaryMagicLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Success gradient for positive feedback
  static const LinearGradient successGradient = LinearGradient(
    colors: [successGlow, successGlowLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Background gradient for main screens
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [neutralDark, neutralMedium, neutralLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Get subject-specific gradient
  static LinearGradient getSubjectGradient(String subjectKey) {
    final color = getSubjectColor(subjectKey);
    final lightColor = getSubjectColorLight(subjectKey);
    return LinearGradient(
      colors: [color, lightColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  // ===== Helpers to derive color variants =====
  static Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final l = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
    }

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

  static Color _blendWithWhite(Color c, double amount) {
    return Color.lerp(c, Colors.white, amount) ?? c;
  }
  
  // ============ SHADOWS ============
  
  /// Subtle shadow for cards
  static const List<BoxShadow> shadowSubtle = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  /// Medium shadow for elevated elements
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  
  /// Strong shadow for floating elements
  static const List<BoxShadow> shadowStrong = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
  
  // ============ MATHEMATICS-SPECIFIC STYLING ============
  
  /// Mathematical expression styling
  static const TextStyle mathematicalExpression = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFamily: 'monospace', // Better for mathematical notation
  );
  
  /// Fraction display styling
  static const TextStyle fractionNumerator = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 0.9,
  );
  
  static const TextStyle fractionDenominator = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 0.9,
  );
  
  /// Answer input styling
  static const TextStyle answerInput = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
}

/// Responsive design utilities
class ResponsiveTokens {
  
  /// Device breakpoints
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;
  
  /// Check device type
  static bool isMobile(BuildContext context) => 
    MediaQuery.of(context).size.width < mobileBreakpoint;
  
  static bool isTablet(BuildContext context) => 
    MediaQuery.of(context).size.width >= mobileBreakpoint && 
    MediaQuery.of(context).size.width < tabletBreakpoint;
  
  static bool isDesktop(BuildContext context) => 
    MediaQuery.of(context).size.width >= tabletBreakpoint;
  
  /// Get responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(DesignTokens.spaceMD);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(DesignTokens.spaceLG);
    } else {
      return const EdgeInsets.all(DesignTokens.spaceXL);
    }
  }
  
  /// Get responsive column count for grids
  static int responsiveColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }
  
  /// Get responsive font scale
  static double responsiveFontScale(BuildContext context) {
    if (isMobile(context)) return 0.9;
    if (isTablet(context)) return 1.0;
    return 1.1;
  }
}
