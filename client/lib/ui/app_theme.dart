import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData theme() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final scheme = ColorScheme.fromSeed(
      seedColor: DesignTokens.primaryTechOrange,
      brightness: Brightness.dark,
    );
    
    return base.copyWith(
      colorScheme: scheme.copyWith(
        primary: DesignTokens.primaryTechOrange,
        secondary: DesignTokens.accentTechCyan,
        tertiary: DesignTokens.primaryTechOrangeLight,
        surface: DesignTokens.neutralSurface,
        background: DesignTokens.neutralDark,
        error: DesignTokens.errorPulse,
      ),
      
      // Enhanced text theme with design tokens
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: DesignTokens.heroTitle.copyWith(color: Colors.white),
        displayMedium: DesignTokens.sectionTitle.copyWith(color: Colors.white),
        displaySmall: DesignTokens.subtitle.copyWith(color: Colors.white),
        headlineLarge: DesignTokens.sectionTitle.copyWith(color: Colors.white),
        headlineMedium: DesignTokens.subtitle.copyWith(color: Colors.white),
        headlineSmall: DesignTokens.problemText.copyWith(color: Colors.white),
        titleLarge: DesignTokens.subtitle.copyWith(color: Colors.white),
        titleMedium: DesignTokens.problemText.copyWith(color: Colors.white),
        titleSmall: DesignTokens.bodyText.copyWith(color: Colors.white),
        bodyLarge: DesignTokens.bodyText.copyWith(color: Colors.white),
        bodyMedium: DesignTokens.bodyText.copyWith(color: Colors.white),
        bodySmall: DesignTokens.captionText.copyWith(color: Colors.white),
        labelLarge: DesignTokens.buttonText.copyWith(color: Colors.white),
        labelMedium: DesignTokens.captionText.copyWith(color: Colors.white),
        labelSmall: DesignTokens.captionText.copyWith(color: Colors.white),
      ),
      
      // Enhanced app bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: DesignTokens.sectionTitle.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      // Enhanced button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primaryMagic,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceLG,
            vertical: DesignTokens.spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
          textStyle: DesignTokens.buttonText,
          elevation: DesignTokens.elevationCard,
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DesignTokens.primaryMagic,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceLG,
            vertical: DesignTokens.spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
          textStyle: DesignTokens.buttonText,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.primaryMagic,
          side: BorderSide(color: DesignTokens.primaryMagic, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceLG,
            vertical: DesignTokens.spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
          textStyle: DesignTokens.buttonText,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.primaryMagic,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceMD,
            vertical: DesignTokens.spaceSM,
          ),
          textStyle: DesignTokens.buttonText,
        ),
      ),
      
      // Enhanced input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.neutralSurface.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          borderSide: BorderSide(color: DesignTokens.primaryMagic, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          borderSide: BorderSide(color: DesignTokens.errorPulse, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          borderSide: BorderSide(color: DesignTokens.errorPulse, width: 2),
        ),
        hintStyle: DesignTokens.bodyText.copyWith(
          color: Colors.white.withOpacity(0.6),
        ),
        labelStyle: DesignTokens.bodyText.copyWith(color: Colors.white),
        contentPadding: const EdgeInsets.all(DesignTokens.spaceMD),
      ),
      
      // Enhanced card theme
      cardTheme: CardThemeData(
        color: DesignTokens.neutralSurface.withOpacity(0.4),
        elevation: DesignTokens.elevationCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        ),
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      
      // Enhanced chip theme
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: DesignTokens.neutralSurface.withOpacity(0.7),
        labelStyle: DesignTokens.captionText.copyWith(color: Colors.white),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
        ),
      ),
      
      // Enhanced dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: DesignTokens.neutralSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        ),
        elevation: DesignTokens.elevationModal,
        titleTextStyle: DesignTokens.sectionTitle.copyWith(color: Colors.white),
        contentTextStyle: DesignTokens.bodyText.copyWith(color: Colors.white),
      ),
      
      // Enhanced bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: DesignTokens.neutralSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DesignTokens.radiusLG),
            topRight: Radius.circular(DesignTokens.radiusLG),
          ),
        ),
        elevation: DesignTokens.elevationModal,
      ),
      
      // Enhanced floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: DesignTokens.primaryMagic,
        foregroundColor: Colors.white,
        elevation: DesignTokens.elevationFAB,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
      ),
      
      // Enhanced list tile theme
      listTileTheme: ListTileThemeData(
        textColor: Colors.white,
        iconColor: Colors.white,
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceMD,
          vertical: DesignTokens.spaceSM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
      ),
      
      // Enhanced switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return DesignTokens.primaryMagic;
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
      
      // Enhanced slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: DesignTokens.primaryMagic,
        inactiveTrackColor: DesignTokens.primaryMagic.withOpacity(0.3),
        thumbColor: Colors.white,
        overlayColor: DesignTokens.primaryMagic.withOpacity(0.2),
        valueIndicatorColor: DesignTokens.primaryMagic,
        valueIndicatorTextStyle: DesignTokens.captionText.copyWith(
          color: Colors.white,
        ),
      ),
      
      // Enhanced progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: DesignTokens.primaryMagic,
        linearTrackColor: DesignTokens.primaryMagic.withOpacity(0.3),
        circularTrackColor: DesignTokens.primaryMagic.withOpacity(0.3),
      ),
      
      // Enhanced snack bar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DesignTokens.neutralSurface,
        contentTextStyle: DesignTokens.bodyText.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: DesignTokens.elevationCard,
      ),
    );
  }
}

class AppGradients {
  // Neutral, sample-based dark hero gradient
  static const List<Color> heroDark = [Color(0xFF121316), Color(0xFF17181D), Color(0xFF1F2026)];
  static const List<Color> heroLight = [Color(0xFFFFFFFF), Color(0xFFF8FAFC), Color(0xFFF2F4F8)];

  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF5BA843), Color(0xFF3B969D), Color(0xFF6C38B8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
}

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Gradient? borderGradient;
  const Glass({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 20, this.borderGradient});

  @override
  Widget build(BuildContext context) {
    final gradient = borderGradient ?? AppGradients.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: GradientBoxBorder(gradient: gradient, width: 1),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class GradientBoxBorder extends BoxBorder {
  final Gradient gradient;
  final double width;
  const GradientBoxBorder({required this.gradient, this.width = 1});

  @override
  BorderSide get top => BorderSide.none;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  ShapeBorder scale(double t) => this;

  @override
  bool get isUniform => false;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect.deflate(width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection, BoxShape shape = BoxShape.rectangle, BorderRadius? borderRadius}) {
    final rrect = (borderRadius ?? BorderRadius.circular(20)).toRRect(rect);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    canvas.drawRRect(rrect, paint);
  }
}

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final isDark = scheme.brightness == Brightness.dark;

        // Base tones derived from theme to support light/dark
        final base1 = isDark ? AppGradients.heroDark[0] : AppGradients.heroLight[0];
        final base2 = isDark ? AppGradients.heroDark[1] : AppGradients.heroLight[1];
        final base3 = isDark ? AppGradients.heroDark[2] : AppGradients.heroLight[2];

        // Subtle breathing using lightness shift
        Color shift(Color c, double amount) {
          final hsl = HSLColor.fromColor(c);
          final l = (hsl.lightness + amount).clamp(0.0, 1.0);
          return hsl.withLightness(l).toColor();
        }

        final t = (math.sin(_c.value * math.pi) * (isDark ? 0.04 : 0.03));
        final c1 = shift(base1, t);
        final c2 = shift(base2, -t * 0.8);
        final c3 = shift(base3, t * 0.6);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                c1,
                c2,
                c3,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class XPBar extends StatelessWidget {
  final int xp;
  final int goal;
  const XPBar({super.key, required this.xp, this.goal = 100});
  @override
  Widget build(BuildContext context) {
    final pct = (xp % goal) / goal;
    return Glass(
      padding: const EdgeInsets.all(10),
      radius: 16,
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(children: [
              Container(height: 10, color: Colors.white.withOpacity(0.12)),
              FractionallySizedBox(
                widthFactor: pct.clamp(0.02, 1.0),
                child: Container(height: 10, decoration: const BoxDecoration(gradient: AppGradients.primary)),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        Text('${xp % goal}/${goal}', style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class StreakPill extends StatelessWidget {
  final int days;
  const StreakPill({super.key, required this.days});
  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      radius: 24,
      child: Row(children: [
        const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent),
        const SizedBox(width: 6),
        Text('$days day streak', style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
