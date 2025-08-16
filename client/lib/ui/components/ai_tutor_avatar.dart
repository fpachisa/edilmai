import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_tokens.dart';

/// AI Tutor Avatar - An animated character with contextual expressions
/// 
/// Features:
/// - Contextual expressions based on student performance
/// - Smooth animations between emotion states
/// - Speech bubble interactions
/// - Personality-based responses
/// - Adaptive feedback based on learning progress
class AITutorAvatar extends StatefulWidget {
  final AvatarEmotion emotion;
  final String? speechText;
  final bool showSpeechBubble;
  final VoidCallback? onTap;
  final double size;
  final bool isAnimated;
  
  const AITutorAvatar({
    super.key,
    this.emotion = AvatarEmotion.neutral,
    this.speechText,
    this.showSpeechBubble = false,
    this.onTap,
    this.size = 80,
    this.isAnimated = true,
  });

  @override
  State<AITutorAvatar> createState() => _AITutorAvatarState();
}

class _AITutorAvatarState extends State<AITutorAvatar>
    with TickerProviderStateMixin {
  
  late AnimationController _blinkController;
  late AnimationController _bounceController;
  late AnimationController _speechController;
  late AnimationController _emotionController;
  
  late Animation<double> _blinkAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _speechScaleAnimation;
  late Animation<double> _speechOpacityAnimation;
  late Animation<double> _emotionAnimation;
  
  AvatarEmotion _currentEmotion = AvatarEmotion.neutral;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _currentEmotion = widget.emotion;
  }
  
  void _initializeAnimations() {
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _speechController = AnimationController(
      duration: DesignTokens.smoothFlow,
      vsync: this,
    );
    
    _emotionController = AnimationController(
      duration: DesignTokens.smoothFlow,
      vsync: this,
    );
    
    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _speechScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _speechController,
      curve: Curves.easeOutBack,
    ));
    
    _speechOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _speechController,
      curve: Curves.easeOut,
    ));
    
    _emotionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _emotionController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isAnimated) {
      _startIdleAnimations();
    }
    
    if (widget.showSpeechBubble) {
      _speechController.forward();
    }
  }
  
  void _startIdleAnimations() {
    // Random blinking
    _scheduleNextBlink();
    
    // Gentle floating animation
    _bounceController.repeat(reverse: true);
  }
  
  void _scheduleNextBlink() {
    Future.delayed(Duration(seconds: 2 + math.Random().nextInt(4)), () {
      if (mounted && widget.isAnimated) {
        _blinkController.forward().then((_) {
          _blinkController.reverse();
          _scheduleNextBlink();
        });
      }
    });
  }
  
  @override
  void didUpdateWidget(AITutorAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle emotion changes
    if (widget.emotion != oldWidget.emotion) {
      _changeEmotion(widget.emotion);
    }
    
    // Handle speech bubble
    if (widget.showSpeechBubble != oldWidget.showSpeechBubble) {
      if (widget.showSpeechBubble) {
        _speechController.forward();
      } else {
        _speechController.reverse();
      }
    }
  }
  
  void _changeEmotion(AvatarEmotion newEmotion) {
    _currentEmotion = newEmotion;
    _emotionController.forward().then((_) {
      _emotionController.reverse();
    });
  }
  
  @override
  void dispose() {
    _blinkController.dispose();
    _bounceController.dispose();
    _speechController.dispose();
    _emotionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _blinkController,
          _bounceController,
          _speechController,
          _emotionController,
        ]),
        builder: (context, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Speech bubble
              if (widget.showSpeechBubble && widget.speechText != null)
                _buildSpeechBubble(),
              
              // Avatar
              Transform.translate(
                offset: Offset(
                  0,
                  widget.isAnimated ? math.sin(_bounceAnimation.value * math.pi) * 3 : 0,
                ),
                child: _buildAvatar(),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSpeechBubble() {
    return Positioned(
      bottom: widget.size + 10,
      left: -50,
      right: -50,
      child: Transform.scale(
        scale: _speechScaleAnimation.value,
        child: Opacity(
          opacity: _speechOpacityAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spaceMD),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              boxShadow: DesignTokens.shadowMedium,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.speechText!,
                  style: DesignTokens.bodyText.copyWith(
                    color: DesignTokens.neutralDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Speech bubble tail
                Transform.translate(
                  offset: const Offset(0, DesignTokens.spaceMD),
                  child: CustomPaint(
                    size: const Size(20, 10),
                    painter: _SpeechBubbleTailPainter(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: _getEmotionGradient(),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getEmotionColor().withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _AvatarFacePainter(
          emotion: _currentEmotion,
          blinkProgress: _blinkAnimation.value,
          emotionTransition: _emotionAnimation.value,
        ),
      ),
    );
  }
  
  LinearGradient _getEmotionGradient() {
    switch (_currentEmotion) {
      case AvatarEmotion.happy:
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
        );
      case AvatarEmotion.excited:
        return const LinearGradient(
          colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
        );
      case AvatarEmotion.encouraging:
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF03DAC6)],
        );
      case AvatarEmotion.thinking:
        return const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFE1BEE7)],
        );
      case AvatarEmotion.concerned:
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFCC02)],
        );
      case AvatarEmotion.neutral:
      default:
        return LinearGradient(
          colors: [DesignTokens.primaryMagic, DesignTokens.primaryMagicLight],
        );
    }
  }
  
  Color _getEmotionColor() {
    switch (_currentEmotion) {
      case AvatarEmotion.happy:
        return const Color(0xFF4CAF50);
      case AvatarEmotion.excited:
        return const Color(0xFFFF9800);
      case AvatarEmotion.encouraging:
        return const Color(0xFF2196F3);
      case AvatarEmotion.thinking:
        return const Color(0xFF9C27B0);
      case AvatarEmotion.concerned:
        return const Color(0xFFFF9800);
      case AvatarEmotion.neutral:
      default:
        return DesignTokens.primaryMagic;
    }
  }
}

/// Custom painter for the avatar's facial features
class _AvatarFacePainter extends CustomPainter {
  final AvatarEmotion emotion;
  final double blinkProgress;
  final double emotionTransition;
  
  _AvatarFacePainter({
    required this.emotion,
    required this.blinkProgress,
    required this.emotionTransition,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw eyes
    _drawEyes(canvas, center, size);
    
    // Draw mouth based on emotion
    _drawMouth(canvas, center, size);
    
    // Draw additional features based on emotion
    _drawEmotionFeatures(canvas, center, size);
  }
  
  void _drawEyes(Canvas canvas, Offset center, Size size) {
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final pupilPaint = Paint()
      ..color = DesignTokens.neutralDark
      ..style = PaintingStyle.fill;
    
    // Eye positions
    final leftEyeCenter = Offset(center.dx - size.width * 0.15, center.dy - size.height * 0.1);
    final rightEyeCenter = Offset(center.dx + size.width * 0.15, center.dy - size.height * 0.1);
    
    final eyeRadius = size.width * 0.08;
    final pupilRadius = eyeRadius * 0.6;
    
    // Eye whites
    canvas.drawCircle(leftEyeCenter, eyeRadius, eyePaint);
    canvas.drawCircle(rightEyeCenter, eyeRadius, eyePaint);
    
    // Blinking effect
    if (blinkProgress < 1.0) {
      // Pupils
      canvas.drawCircle(
        leftEyeCenter,
        pupilRadius * blinkProgress,
        pupilPaint,
      );
      canvas.drawCircle(
        rightEyeCenter,
        pupilRadius * blinkProgress,
        pupilPaint,
      );
      
      // Eye shine
      final shinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        leftEyeCenter.translate(-pupilRadius * 0.3, -pupilRadius * 0.3),
        pupilRadius * 0.3 * blinkProgress,
        shinePaint,
      );
      canvas.drawCircle(
        rightEyeCenter.translate(-pupilRadius * 0.3, -pupilRadius * 0.3),
        pupilRadius * 0.3 * blinkProgress,
        shinePaint,
      );
    }
  }
  
  void _drawMouth(Canvas canvas, Offset center, Size size) {
    final mouthPaint = Paint()
      ..color = DesignTokens.neutralDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final mouthCenter = Offset(center.dx, center.dy + size.height * 0.15);
    
    switch (emotion) {
      case AvatarEmotion.happy:
      case AvatarEmotion.excited:
        _drawSmile(canvas, mouthCenter, size.width * 0.2, mouthPaint);
        break;
      case AvatarEmotion.encouraging:
        _drawGentleSmile(canvas, mouthCenter, size.width * 0.15, mouthPaint);
        break;
      case AvatarEmotion.thinking:
        _drawThinkingMouth(canvas, mouthCenter, size.width * 0.1, mouthPaint);
        break;
      case AvatarEmotion.concerned:
        _drawConcernedMouth(canvas, mouthCenter, size.width * 0.15, mouthPaint);
        break;
      case AvatarEmotion.neutral:
      default:
        _drawNeutralMouth(canvas, mouthCenter, size.width * 0.12, mouthPaint);
        break;
    }
  }
  
  void _drawSmile(Canvas canvas, Offset center, double width, Paint paint) {
    final path = Path();
    path.addArc(
      Rect.fromCenter(center: center, width: width, height: width * 0.6),
      0.3,
      math.pi * 0.4,
    );
    canvas.drawPath(path, paint);
  }
  
  void _drawGentleSmile(Canvas canvas, Offset center, double width, Paint paint) {
    final path = Path();
    path.addArc(
      Rect.fromCenter(center: center, width: width, height: width * 0.4),
      0.4,
      math.pi * 0.3,
    );
    canvas.drawPath(path, paint);
  }
  
  void _drawThinkingMouth(Canvas canvas, Offset center, double width, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - width / 2, center.dy),
      Offset(center.dx + width / 2, center.dy),
      paint,
    );
  }
  
  void _drawConcernedMouth(Canvas canvas, Offset center, double width, Paint paint) {
    final path = Path();
    path.addArc(
      Rect.fromCenter(center: center.translate(0, width * 0.3), width: width, height: width * 0.4),
      math.pi + 0.4,
      math.pi * 0.3,
    );
    canvas.drawPath(path, paint);
  }
  
  void _drawNeutralMouth(Canvas canvas, Offset center, double width, Paint paint) {
    canvas.drawCircle(center, width * 0.15, paint..style = PaintingStyle.fill);
  }
  
  void _drawEmotionFeatures(Canvas canvas, Offset center, Size size) {
    switch (emotion) {
      case AvatarEmotion.excited:
        _drawExcitementSparkles(canvas, center, size);
        break;
      case AvatarEmotion.thinking:
        _drawThoughtBubble(canvas, center, size);
        break;
      default:
        break;
    }
  }
  
  void _drawExcitementSparkles(Canvas canvas, Offset center, Size size) {
    final sparklePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    // Draw small sparkles around the avatar
    final sparklePositions = [
      Offset(center.dx - size.width * 0.3, center.dy - size.height * 0.2),
      Offset(center.dx + size.width * 0.3, center.dy - size.height * 0.3),
      Offset(center.dx + size.width * 0.25, center.dy + size.height * 0.2),
    ];
    
    for (final position in sparklePositions) {
      _drawSparkle(canvas, position, size.width * 0.03, sparklePaint);
    }
  }
  
  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    
    // Create a 4-pointed star
    final points = <Offset>[];
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final radius = (i % 2 == 0) ? size : size * 0.4;
      points.add(Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      ));
    }
    
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawThoughtBubble(Canvas canvas, Offset center, Size size) {
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    // Draw thought bubble dots
    final dotPositions = [
      Offset(center.dx + size.width * 0.35, center.dy - size.height * 0.4),
      Offset(center.dx + size.width * 0.32, center.dy - size.height * 0.35),
      Offset(center.dx + size.width * 0.28, center.dy - size.height * 0.32),
    ];
    
    for (int i = 0; i < dotPositions.length; i++) {
      canvas.drawCircle(
        dotPositions[i],
        (3 - i) * 2.0,
        bubblePaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for speech bubble tail
class _SpeechBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(size.width / 2 - 10, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width / 2 + 10, 0);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Avatar emotion states
enum AvatarEmotion {
  neutral,
  happy,
  excited,
  encouraging,
  thinking,
  concerned,
}