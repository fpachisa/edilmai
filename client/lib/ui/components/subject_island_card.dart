import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_tokens.dart';
import '../app_theme.dart';

/// Subject Island Card - A floating 3D card representing a mathematical subject
/// 
/// Features:
/// - 3D hover effects with parallax motion
/// - Animated progress indicators
/// - Subject-specific theming and icons
/// - Engaging micro-interactions
/// - Accessibility support
class SubjectIslandCard extends StatefulWidget {
  final String subject;
  final String displayName;
  final int completedProblems;
  final int totalProblems;
  final double masteryPercentage;
  final VoidCallback onTap;
  final bool isLocked;
  final List<String> recentAchievements;
  
  const SubjectIslandCard({
    super.key,
    required this.subject,
    required this.displayName,
    required this.completedProblems,
    required this.totalProblems,
    required this.masteryPercentage,
    required this.onTap,
    this.isLocked = false,
    this.recentAchievements = const [],
  });

  @override
  State<SubjectIslandCard> createState() => _SubjectIslandCardState();
}

class _SubjectIslandCardState extends State<SubjectIslandCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _hoverController = AnimationController(
      duration: DesignTokens.smoothFlow,
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: DesignTokens.dramaticReveal,
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    // Set up animations
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.masteryPercentage / 100,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutExpo,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start progress animation
    _progressController.forward();
  }
  
  @override
  void dispose() {
    _hoverController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  void _onHoverChange(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _hoverController.forward();
      // Start magical pulse effect on hover
      if (!widget.isLocked) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _hoverController.reverse();
      _pulseController.stop();
      _pulseController.reset();
    }
  }
  
  IconData _getSubjectIcon() {
    switch (widget.subject.toLowerCase()) {
      case 'algebra': return Icons.functions_rounded;
      case 'fractions': return Icons.pie_chart_rounded;
      case 'geometry': return Icons.change_history_rounded;
      case 'speed': return Icons.speed_rounded;
      case 'ratio': return Icons.balance_rounded;
      case 'percentage': return Icons.percent_rounded;
      case 'statistics': return Icons.bar_chart_rounded;
      default: return Icons.calculate_rounded;
    }
  }
  
  String _getSubjectEmoji() {
    switch (widget.subject.toLowerCase()) {
      case 'algebra': return '🔮';
      case 'fractions': return '🍰';
      case 'geometry': return '🏛️';
      case 'speed': return '⚡';
      case 'ratio': return '⚖️';
      case 'percentage': return '📊';
      case 'statistics': return '📈';
      default: return '🧮';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final subjectColor = DesignTokens.getSubjectColor(widget.subject);
    final subjectColorLight = DesignTokens.getSubjectColorLight(widget.subject);
    final subjectColorGlow = DesignTokens.getSubjectColorGlow(widget.subject);
    final magicalGradient = DesignTokens.getMagicalSubjectGradient(widget.subject);
    
    final completionRatio = widget.totalProblems > 0 
        ? widget.completedProblems / widget.totalProblems 
        : 0.0;
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _hoverController,
        _progressController,
        _pulseController,
      ]),
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _onHoverChange(true),
          onExit: (_) => _onHoverChange(false),
          child: GestureDetector(
            onTap: widget.isLocked ? null : () {
              // Add haptic feedback for better user experience
              // HapticFeedback.lightImpact(); // Uncomment if you want haptic feedback
              
              // Quick scale animation on tap for satisfying feedback
              _hoverController.forward().then((_) {
                _hoverController.reverse();
              });
              
              widget.onTap();
            },
            onTapDown: widget.isLocked ? null : (_) {
              _hoverController.forward();
            },
            onTapUp: widget.isLocked ? null : (_) {
              Future.delayed(const Duration(milliseconds: 100), () {
                _hoverController.reverse();
              });
            },
            onTapCancel: widget.isLocked ? null : () {
              _hoverController.reverse();
            },
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  height: 80, // Much smaller for compact display
                  margin: const EdgeInsets.all(1), // Minimal margin
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
                    gradient: widget.isLocked 
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF424242),
                              Color(0xFF616161),
                            ],
                          )
                        : magicalGradient,
                    boxShadow: [
                      // Main shadow with magical glow
                      BoxShadow(
                        color: widget.isLocked 
                            ? Colors.black26
                            : subjectColorGlow.withOpacity(0.4 + (_elevationAnimation.value * 0.01)),
                        blurRadius: 20 + (_elevationAnimation.value * 0.3),
                        offset: Offset(0, 8 + (_elevationAnimation.value * 0.1)),
                        spreadRadius: 2 + (_elevationAnimation.value * 0.05),
                      ),
                      // Inner glow for depth
                      if (!widget.isLocked)
                        BoxShadow(
                          color: subjectColorLight.withOpacity(0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: -2,
                        ),
                      // Subtle highlight
                      if (!widget.isLocked)
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, -1),
                          spreadRadius: -3,
                        ),
                    ],
                    // Add subtle border for definition
                    border: !widget.isLocked 
                        ? Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1,
                          )
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
                    child: Stack(
                      children: [
                        // Background pattern
                        _buildBackgroundPattern(),
                        
                        // Magical shimmer effect
                        if (!widget.isLocked) _buildShimmerEffect(),
                        
                        // Lock overlay for locked subjects
                        if (widget.isLocked) _buildLockOverlay(),
                        
                        // Main content
                        _buildMainContent(subjectColor, subjectColorLight),
                        
                        // Progress indicator
                        if (!widget.isLocked) _buildProgressIndicator(),
                        
                        // Achievement badges
                        if (widget.recentAchievements.isNotEmpty && !widget.isLocked)
                          _buildAchievementBadges(),
                        
                        // Pulse effect for new achievements
                        if (widget.recentAchievements.isNotEmpty && !widget.isLocked)
                          _buildPulseEffect(subjectColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _SubjectPatternPainter(
          subject: widget.subject,
          opacity: 0.1,
        ),
      ),
    );
  }
  
  Widget _buildLockOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        ),
        child: const Center(
          child: Icon(
            Icons.lock_rounded,
            color: Colors.white70,
            size: 40,
          ),
        ),
      ),
    );
  }
  
  Widget _buildMainContent(Color subjectColor, Color subjectColorLight) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceXS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject icon and emoji
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    _getSubjectIcon(),
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  _getSubjectEmoji(),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Subject name
            Text(
              widget.displayName,
              style: DesignTokens.sectionTitle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 2),
            
            // Progress stats
            if (!widget.isLocked) ...[
              Text(
                '${widget.masteryPercentage.toInt()}% complete',
                style: DesignTokens.captionText.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: 8,
                ),
              ),
            ] else ...[
              Text(
                'Locked',
                style: DesignTokens.bodyText.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 8,
                ),
              ),
            ],
            
            const Spacer(),
            
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    final progress = _progressAnimation.value;
    
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(DesignTokens.radiusLG),
            bottomRight: Radius.circular(DesignTokens.radiusLG),
          ),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(DesignTokens.radiusLG),
                bottomRight: Radius.circular(DesignTokens.radiusLG),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAchievementBadges() {
    return Positioned(
      top: DesignTokens.spaceSM,
      right: DesignTokens.spaceSM,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceXS,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.successGlow,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 12,
            ),
            const SizedBox(width: 2),
            Text(
              '${widget.recentAchievements.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPulseEffect(Color subjectColor) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
          border: Border.all(
            color: subjectColor.withOpacity(_pulseAnimation.value * 0.5),
            width: 2,
          ),
        ),
      ),
    );
  }
  
  /// Creates a magical shimmer effect that flows across the card
  Widget _buildShimmerEffect() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              (_hoverController.value - 0.5) * 100,
              (_hoverController.value - 0.5) * 20,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-1.5, -0.5),
                  end: const Alignment(1.5, 0.5),
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.1 * _hoverController.value),
                    Colors.white.withOpacity(0.3 * _hoverController.value),
                    Colors.white.withOpacity(0.1 * _hoverController.value),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for subject-specific background patterns
class _SubjectPatternPainter extends CustomPainter {
  final String subject;
  final double opacity;
  
  const _SubjectPatternPainter({
    required this.subject,
    this.opacity = 0.1,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    switch (subject.toLowerCase()) {
      case 'algebra':
        _drawAlgebraPattern(canvas, size, paint);
        break;
      case 'fractions':
        _drawFractionsPattern(canvas, size, paint);
        break;
      case 'geometry':
        _drawGeometryPattern(canvas, size, paint);
        break;
      case 'speed':
        _drawSpeedPattern(canvas, size, paint);
        break;
      case 'ratio':
        _drawRatioPattern(canvas, size, paint);
        break;
      case 'percentage':
        _drawPercentagePattern(canvas, size, paint);
        break;
      case 'statistics':
        _drawStatisticsPattern(canvas, size, paint);
        break;
    }
  }
  
  void _drawAlgebraPattern(Canvas canvas, Size size, Paint paint) {
    // Draw mathematical symbols (x, y, =, +)
    final path = Path();
    
    // Draw scattered X symbols
    for (int i = 0; i < 6; i++) {
      final x = (i * 0.3 + 0.1) * size.width;
      final y = (i * 0.2 + 0.2) * size.height;
      
      path.moveTo(x - 8, y - 8);
      path.lineTo(x + 8, y + 8);
      path.moveTo(x + 8, y - 8);
      path.lineTo(x - 8, y + 8);
    }
    
    canvas.drawPath(path, paint);
  }
  
  void _drawFractionsPattern(Canvas canvas, Size size, Paint paint) {
    // Draw pie slice patterns
    final center = Offset(size.width * 0.8, size.height * 0.3);
    final radius = 30.0;
    
    for (int i = 0; i < 8; i++) {
      final startAngle = (i * math.pi / 4);
      final sweepAngle = math.pi / 8;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }
  
  void _drawGeometryPattern(Canvas canvas, Size size, Paint paint) {
    // Draw geometric shapes
    final path = Path();
    
    // Triangle
    path.moveTo(size.width * 0.2, size.height * 0.7);
    path.lineTo(size.width * 0.4, size.height * 0.3);
    path.lineTo(size.width * 0.6, size.height * 0.7);
    path.close();
    
    // Circle
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.6),
      20,
      paint,
    );
    
    canvas.drawPath(path, paint);
  }
  
  void _drawSpeedPattern(Canvas canvas, Size size, Paint paint) {
    // Draw arrow patterns suggesting movement
    final path = Path();
    
    for (int i = 0; i < 4; i++) {
      final y = size.height * (0.2 + i * 0.2);
      final startX = size.width * 0.1;
      final endX = size.width * 0.9;
      
      // Arrow line
      path.moveTo(startX, y);
      path.lineTo(endX, y);
      
      // Arrow head
      path.lineTo(endX - 10, y - 5);
      path.moveTo(endX, y);
      path.lineTo(endX - 10, y + 5);
    }
    
    canvas.drawPath(path, paint);
  }
  
  void _drawRatioPattern(Canvas canvas, Size size, Paint paint) {
    // Draw balance/ratio patterns
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.5;
    
    // Balance beam
    canvas.drawLine(
      Offset(centerX - 40, centerY),
      Offset(centerX + 40, centerY),
      paint,
    );
    
    // Left side
    canvas.drawLine(
      Offset(centerX - 30, centerY),
      Offset(centerX - 30, centerY + 20),
      paint,
    );
    
    // Right side
    canvas.drawLine(
      Offset(centerX + 30, centerY),
      Offset(centerX + 30, centerY + 20),
      paint,
    );
  }
  
  void _drawPercentagePattern(Canvas canvas, Size size, Paint paint) {
    // Draw percentage symbols and grid
    final path = Path();
    
    // Draw % symbols
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.3 + i * 0.3);
      final y = size.height * (0.3 + i * 0.2);
      
      // Top circle
      canvas.drawCircle(Offset(x - 6, y - 6), 3, paint);
      
      // Bottom circle
      canvas.drawCircle(Offset(x + 6, y + 6), 3, paint);
      
      // Diagonal line
      path.moveTo(x - 8, y + 8);
      path.lineTo(x + 8, y - 8);
    }
    
    canvas.drawPath(path, paint);
  }
  
  void _drawStatisticsPattern(Canvas canvas, Size size, Paint paint) {
    // Draw bar chart pattern
    final barWidth = size.width * 0.08;
    final heights = [0.3, 0.6, 0.4, 0.8, 0.5];
    
    for (int i = 0; i < heights.length; i++) {
      final x = size.width * (0.15 + i * 0.15);
      final barHeight = size.height * heights[i];
      
      canvas.drawRect(
        Rect.fromLTWH(
          x,
          size.height - barHeight - 20,
          barWidth,
          barHeight,
        ),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}