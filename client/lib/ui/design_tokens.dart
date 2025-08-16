import 'package:flutter/material.dart';

/// Enhanced Design Tokens for PSLE AI Tutor
/// 
/// Provides consistent colors, typography, spacing, and timing
/// across the entire application with mathematical subject theming.
class DesignTokens {
  
  // ============ CORE COLORS ============
  
  /// Primary brand colors with magical theme
  static const Color primaryMagic = Color(0xFF6C63FF);
  static const Color primaryMagicLight = Color(0xFF9C95FF);
  static const Color primaryMagicDark = Color(0xFF4A43CC);
  
  /// Feedback colors with glowing effects
  static const Color successGlow = Color(0xFF00E676);
  static const Color successGlowLight = Color(0xFF66FFA6);
  static const Color successGlowDark = Color(0xFF00C853);
  
  static const Color warningAura = Color(0xFFFFAB00);
  static const Color warningAuraLight = Color(0xFFFFCC66);
  static const Color warningAuraDark = Color(0xFFCC8900);
  
  static const Color errorPulse = Color(0xFFFF5252);
  static const Color errorPulseLight = Color(0xFFFF8A80);
  static const Color errorPulseDark = Color(0xFFD32F2F);
  
  /// Neutral colors for backgrounds and text
  static const Color neutralDark = Color(0xFF0F1024);
  static const Color neutralMedium = Color(0xFF1A1E3A);
  static const Color neutralLight = Color(0xFF2B2F5B);
  static const Color neutralSurface = Color(0xFF1E2139);
  
  // ============ MAGICAL SUBJECT COLORS ============
  
  /// Each mathematical subject has its own vibrant, engaging color palette
  /// Designed to be fun, memorable, and inspiring for young learners
  
  // 🟣 ALGEBRA MYSTIC - Deep purple with magical vibes
  static const Color algebraMystic = Color(0xFF8E44AD);
  static const Color algebraMysticLight = Color(0xFFE8DAEF);
  static const Color algebraMysticDark = Color(0xFF6C3483);
  static const Color algebraMysticGlow = Color(0xFFBB8FCE);
  
  // 🟢 FRACTIONS FOREST - Vibrant green like a lush forest
  static const Color fractionForest = Color(0xFF27AE60);
  static const Color fractionForestLight = Color(0xFFD5F4E6);
  static const Color fractionForestDark = Color(0xFF1E8449);
  static const Color fractionForestGlow = Color(0xFF82E0AA);
  
  // 🟠 PERCENTAGE PLANET - Warm orange like a sunset planet
  static const Color percentagePlanet = Color(0xFFE67E22);
  static const Color percentagePlanetLight = Color(0xFFFDEBD0);
  static const Color percentagePlanetDark = Color(0xFFD35400);
  static const Color percentagePlanetGlow = Color(0xFFF8C471);
  
  // ⚡ SPEED STORM - Electric yellow like lightning
  static const Color speedStorm = Color(0xFFF1C40F);
  static const Color speedStormLight = Color(0xFFFEF9E7);
  static const Color speedStormDark = Color(0xFFD4AC0D);
  static const Color speedStormGlow = Color(0xFFF7DC6F);
  
  // 💖 RATIO REALM - Bright pink like magical crystals
  static const Color ratioRealm = Color(0xFFE91E63);
  static const Color ratioRealmLight = Color(0xFFFCE4EC);
  static const Color ratioRealmDark = Color(0xFFC2185B);
  static const Color ratioRealmGlow = Color(0xFFF8BBD9);
  
  // 🔵 GEOMETRY GALAXY - Cosmic blue like deep space
  static const Color geometryGalaxy = Color(0xFF3498DB);
  static const Color geometryGalaxyLight = Color(0xFFEBF5FB);
  static const Color geometryGalaxyDark = Color(0xFF2980B9);
  static const Color geometryGalaxyGlow = Color(0xFF85C1E9);
  
  // 🟤 STATISTICS SPACE - Rich copper like ancient treasures
  static const Color statisticsSpace = Color(0xFFD68910);
  static const Color statisticsSpaceLight = Color(0xFFFDF2E9);
  static const Color statisticsSpaceDark = Color(0xFFB7950B);
  static const Color statisticsSpaceGlow = Color(0xFFF4D03F);
  
  /// Get subject color by key
  static Color getSubjectColor(String subjectKey) {
    switch (subjectKey.toLowerCase()) {
      case 'algebra': return algebraMystic;
      case 'fractions': return fractionForest;
      case 'geometry': return geometryGalaxy;
      case 'speed': return speedStorm;
      case 'ratio': return ratioRealm;
      case 'percentage': return percentagePlanet;
      case 'statistics': return statisticsSpace;
      default: return primaryMagic;
    }
  }
  
  /// Get subject light variant
  static Color getSubjectColorLight(String subjectKey) {
    switch (subjectKey.toLowerCase()) {
      case 'algebra': return algebraMysticLight;
      case 'fractions': return fractionForestLight;
      case 'geometry': return geometryGalaxyLight;
      case 'speed': return speedStormLight;
      case 'ratio': return ratioRealmLight;
      case 'percentage': return percentagePlanetLight;
      case 'statistics': return statisticsSpaceLight;
      default: return primaryMagicLight;
    }
  }
  
  /// Get subject dark variant
  static Color getSubjectColorDark(String subjectKey) {
    switch (subjectKey.toLowerCase()) {
      case 'algebra': return algebraMysticDark;
      case 'fractions': return fractionForestDark;
      case 'geometry': return geometryGalaxyDark;
      case 'speed': return speedStormDark;
      case 'ratio': return ratioRealmDark;
      case 'percentage': return percentagePlanetDark;
      case 'statistics': return statisticsSpaceDark;
      default: return primaryMagicDark;
    }
  }
  
  /// Get subject glow variant for magical effects
  static Color getSubjectColorGlow(String subjectKey) {
    switch (subjectKey.toLowerCase()) {
      case 'algebra': return algebraMysticGlow;
      case 'fractions': return fractionForestGlow;
      case 'geometry': return geometryGalaxyGlow;
      case 'speed': return speedStormGlow;
      case 'ratio': return ratioRealmGlow;
      case 'percentage': return percentagePlanetGlow;
      case 'statistics': return statisticsSpaceGlow;
      default: return primaryMagicLight;
    }
  }
  
  /// Get magical gradient that makes topics come alive
  static LinearGradient getMagicalSubjectGradient(String subjectKey) {
    switch (subjectKey.toLowerCase()) {
      case 'algebra':
        return const LinearGradient(
          colors: [algebraMystic, algebraMysticGlow, algebraMysticLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        );
      case 'fractions':
        return const LinearGradient(
          colors: [fractionForest, fractionForestGlow, fractionForestLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        );
      case 'percentage':
        return const LinearGradient(
          colors: [percentagePlanet, percentagePlanetGlow, percentagePlanetLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        );
      case 'speed':
        return const LinearGradient(
          colors: [speedStorm, speedStormGlow, speedStormLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        );
      case 'ratio':
        return const LinearGradient(
          colors: [ratioRealm, ratioRealmGlow, ratioRealmLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        );
      case 'geometry':
        return const LinearGradient(
          colors: [geometryGalaxy, geometryGalaxyGlow, geometryGalaxyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        );
      case 'statistics':
        return const LinearGradient(
          colors: [statisticsSpace, statisticsSpaceGlow, statisticsSpaceLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        );
      default:
        return primaryGradient;
    }
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