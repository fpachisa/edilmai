import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData theme() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final scheme = ColorScheme.fromSeed(
      seedColor: DesignTokens.primaryMagic,
      brightness: Brightness.dark,
    );
    
    return base.copyWith(
      colorScheme: scheme.copyWith(
        primary: DesignTokens.primaryMagic,
        secondary: DesignTokens.primaryMagicLight,
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
  static const List<Color> hero = [Color(0xFF0F1024), Color(0xFF1A1E3A), Color(0xFF2B2F5B)];
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
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
  late final Animation<Color?> _c1;
  late final Animation<Color?> _c2;
  late final Animation<Color?> _c3;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _c1 = ColorTween(begin: const Color(0xFF0F1024), end: const Color(0xFF1B103A)).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    _c2 = ColorTween(begin: const Color(0xFF1A1E3A), end: const Color(0xFF22355A)).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    _c3 = ColorTween(begin: const Color(0xFF2B2F5B), end: const Color(0xFF163047)).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
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
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _c1.value ?? AppGradients.hero[0],
                _c2.value ?? AppGradients.hero[1],
                _c3.value ?? AppGradients.hero[2],
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
