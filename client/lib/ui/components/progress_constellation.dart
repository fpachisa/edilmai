import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_tokens.dart';

/// Progress Constellation - A beautiful star map visualization of learning progress
/// 
/// Features:
/// - Interactive star constellation representing learning topics
/// - Animated connections between completed topics
/// - Twinkling stars for achievements
/// - Zoom and pan capabilities
/// - Beautiful particle effects for milestones
/// - Constellation completion celebrations
class ProgressConstellation extends StatefulWidget {
  final Map<String, ConstellationNode> nodes;
  final List<ConstellationConnection> connections;
  final String? selectedNodeId;
  final Function(String nodeId)? onNodeTap;
  final bool showParticles;
  final double masteryPercentage;
  
  const ProgressConstellation({
    super.key,
    required this.nodes,
    required this.connections,
    this.selectedNodeId,
    this.onNodeTap,
    this.showParticles = true,
    this.masteryPercentage = 0.0,
  });

  @override
  State<ProgressConstellation> createState() => _ProgressConstellationState();
}

class _ProgressConstellationState extends State<ProgressConstellation>
    with TickerProviderStateMixin {
  
  late AnimationController _twinkleController;
  late AnimationController _connectionController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  
  late Animation<double> _twinkleAnimation;
  late Animation<double> _connectionAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;
  
  final TransformationController _transformController = TransformationController();
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _twinkleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _connectionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _twinkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _twinkleController,
      curve: Curves.easeInOut,
    ));
    
    _connectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _connectionController,
      curve: Curves.easeInOut,
    ));
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start connection animation
    _connectionController.forward();
  }
  
  @override
  void dispose() {
    _twinkleController.dispose();
    _connectionController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _transformController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            const Color(0xFF1A1D3A),
            const Color(0xFF0F1024),
            const Color(0xFF000000),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _twinkleController,
          _connectionController,
          _particleController,
          _pulseController,
        ]),
        builder: (context, child) {
          return InteractiveViewer(
            transformationController: _transformController,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 3.0,
            child: CustomPaint(
              size: Size.infinite,
              painter: _ConstellationPainter(
                nodes: widget.nodes,
                connections: widget.connections,
                selectedNodeId: widget.selectedNodeId,
                twinkleAnimation: _twinkleAnimation,
                connectionAnimation: _connectionAnimation,
                particleAnimation: _particleAnimation,
                pulseAnimation: _pulseAnimation,
                showParticles: widget.showParticles,
                masteryPercentage: widget.masteryPercentage,
              ),
              child: GestureDetector(
                onTapDown: _handleTapDown,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (widget.onNodeTap == null) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final localPosition = details.localPosition;
    
    // Check if tap is on any node
    for (final entry in widget.nodes.entries) {
      final nodeId = entry.key;
      final node = entry.value;
      
      final nodePosition = Offset(
        node.position.dx * size.width,
        node.position.dy * size.height,
      );
      
      final distance = (localPosition - nodePosition).distance;
      if (distance <= 40) { // Node tap radius
        widget.onNodeTap!(nodeId);
        break;
      }
    }
  }
}

/// Custom painter for the constellation visualization
class _ConstellationPainter extends CustomPainter {
  final Map<String, ConstellationNode> nodes;
  final List<ConstellationConnection> connections;
  final String? selectedNodeId;
  final Animation<double> twinkleAnimation;
  final Animation<double> connectionAnimation;
  final Animation<double> particleAnimation;
  final Animation<double> pulseAnimation;
  final bool showParticles;
  final double masteryPercentage;
  
  _ConstellationPainter({
    required this.nodes,
    required this.connections,
    this.selectedNodeId,
    required this.twinkleAnimation,
    required this.connectionAnimation,
    required this.particleAnimation,
    required this.pulseAnimation,
    required this.showParticles,
    required this.masteryPercentage,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawConnections(canvas, size);
    _drawNodes(canvas, size);
    if (showParticles) _drawParticles(canvas, size);
    _drawConstellationName(canvas, size);
  }
  
  void _drawBackground(Canvas canvas, Size size) {
    // Draw background stars
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42); // Fixed seed for consistent stars
    
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      
      final twinkle = math.sin(twinkleAnimation.value * math.pi * 2 + i) * 0.3 + 0.7;
      paint.color = Colors.white.withOpacity(0.1 * twinkle);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  void _drawConnections(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    for (final connection in connections) {
      final fromNode = nodes[connection.fromNodeId];
      final toNode = nodes[connection.toNodeId];
      
      if (fromNode == null || toNode == null) continue;
      
      final fromPos = Offset(
        fromNode.position.dx * size.width,
        fromNode.position.dy * size.height,
      );
      
      final toPos = Offset(
        toNode.position.dx * size.width,
        toNode.position.dy * size.height,
      );
      
      // Only draw if both nodes are unlocked
      if (fromNode.isUnlocked && toNode.isUnlocked) {
        // Animated connection drawing
        final progress = connectionAnimation.value;
        final animatedToPos = Offset.lerp(fromPos, toPos, progress)!;
        
        // Gradient connection line
        final gradient = LinearGradient(
          colors: [
            DesignTokens.getSubjectColor(fromNode.subject),
            DesignTokens.getSubjectColor(toNode.subject),
          ],
        );
        
        paint.shader = gradient.createShader(Rect.fromPoints(fromPos, animatedToPos));
        paint.color = Colors.white.withOpacity(0.6);
        
        canvas.drawLine(fromPos, animatedToPos, paint);
        
        // Connection particles
        if (progress > 0.5) {
          _drawConnectionParticles(canvas, fromPos, animatedToPos, paint);
        }
      } else {
        // Locked connection - dotted line
        paint.shader = null;
        paint.color = Colors.white.withOpacity(0.2);
        _drawDottedLine(canvas, fromPos, toPos, paint);
      }
    }
  }
  
  void _drawConnectionParticles(Canvas canvas, Offset start, Offset end, Paint paint) {
    final particlePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 3; i++) {
      final t = (particleAnimation.value + i * 0.3) % 1.0;
      final position = Offset.lerp(start, end, t)!;
      
      final size = (1.0 - (t - 0.5).abs() * 2) * 3;
      canvas.drawCircle(position, size, particlePaint);
    }
  }
  
  void _drawDottedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    
    final distance = (end - start).distance;
    final unitVector = (end - start) / distance;
    
    double currentDistance = 0;
    bool isDash = true;
    
    while (currentDistance < distance) {
      final segmentLength = isDash ? dashWidth : dashSpace;
      final segmentEnd = math.min(currentDistance + segmentLength, distance);
      
      if (isDash) {
        final segmentStart = start + unitVector * currentDistance;
        final segmentEndPoint = start + unitVector * segmentEnd;
        canvas.drawLine(segmentStart, segmentEndPoint, paint);
      }
      
      currentDistance = segmentEnd;
      isDash = !isDash;
    }
  }
  
  void _drawNodes(Canvas canvas, Size size) {
    for (final entry in nodes.entries) {
      final nodeId = entry.key;
      final node = entry.value;
      
      final position = Offset(
        node.position.dx * size.width,
        node.position.dy * size.height,
      );
      
      _drawNode(canvas, position, node, nodeId == selectedNodeId);
    }
  }
  
  void _drawNode(Canvas canvas, Offset position, ConstellationNode node, bool isSelected) {
    final baseRadius = 20.0;
    final radius = isSelected ? baseRadius * pulseAnimation.value : baseRadius;
    
    // Node background
    final backgroundPaint = Paint()
      ..style = PaintingStyle.fill;
    
    if (node.isUnlocked) {
      if (node.isCompleted) {
        // Completed node - glowing effect
        backgroundPaint.shader = RadialGradient(
          colors: [
            DesignTokens.getSubjectColor(node.subject),
            DesignTokens.getSubjectColorLight(node.subject),
            DesignTokens.getSubjectColor(node.subject).withOpacity(0.6),
          ],
        ).createShader(Rect.fromCircle(center: position, radius: radius));
        
        // Glow effect
        final glowPaint = Paint()
          ..color = DesignTokens.getSubjectColor(node.subject).withOpacity(0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        
        canvas.drawCircle(position, radius * 1.5, glowPaint);
      } else {
        // Available node
        backgroundPaint.color = DesignTokens.getSubjectColor(node.subject).withOpacity(0.8);
      }
    } else {
      // Locked node
      backgroundPaint.color = Colors.grey.withOpacity(0.5);
    }
    
    canvas.drawCircle(position, radius, backgroundPaint);
    
    // Node border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(node.isUnlocked ? 0.8 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(position, radius, borderPaint);
    
    // Progress ring for partially completed nodes
    if (node.isUnlocked && !node.isCompleted && node.progress > 0) {
      _drawProgressRing(canvas, position, radius + 5, node.progress);
    }
    
    // Node icon or letter
    _drawNodeIcon(canvas, position, node);
    
    // Completion stars
    if (node.isCompleted) {
      _drawCompletionStars(canvas, position, radius);
    }
    
    // Lock icon for locked nodes
    if (!node.isUnlocked) {
      _drawLockIcon(canvas, position);
    }
  }
  
  void _drawProgressRing(Canvas canvas, Offset center, double radius, double progress) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    
    // Background ring
    canvas.drawCircle(center, radius, paint);
    
    // Progress ring
    paint.color = DesignTokens.successGlow;
    final sweepAngle = 2 * math.pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }
  
  void _drawNodeIcon(Canvas canvas, Offset position, ConstellationNode node) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.label.isNotEmpty ? node.label[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );
    
    textPainter.paint(canvas, offset);
  }
  
  void _drawCompletionStars(Canvas canvas, Offset center, double nodeRadius) {
    final starPaint = Paint()
      ..color = DesignTokens.successGlow
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) + (twinkleAnimation.value * math.pi / 3);
      final starRadius = nodeRadius + 15 + math.sin(twinkleAnimation.value * math.pi * 2) * 3;
      
      final starPosition = Offset(
        center.dx + math.cos(angle) * starRadius,
        center.dy + math.sin(angle) * starRadius,
      );
      
      _drawStar(canvas, starPosition, 4, starPaint);
    }
  }
  
  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const int points = 5;
    const double angle = 2 * math.pi / points;
    
    for (int i = 0; i < points; i++) {
      final outerAngle = i * angle - math.pi / 2;
      final innerAngle = outerAngle + angle / 2;
      
      final outerPoint = Offset(
        center.dx + math.cos(outerAngle) * radius,
        center.dy + math.sin(outerAngle) * radius,
      );
      
      final innerPoint = Offset(
        center.dx + math.cos(innerAngle) * radius * 0.5,
        center.dy + math.sin(innerAngle) * radius * 0.5,
      );
      
      if (i == 0) {
        path.moveTo(outerPoint.dx, outerPoint.dy);
      } else {
        path.lineTo(outerPoint.dx, outerPoint.dy);
      }
      
      path.lineTo(innerPoint.dx, innerPoint.dy);
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawLockIcon(Canvas canvas, Offset center) {
    final lockPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Lock body
    final lockRect = Rect.fromCenter(
      center: center,
      width: 12,
      height: 8,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(lockRect, const Radius.circular(2)),
      lockPaint,
    );
    
    // Lock shackle
    canvas.drawArc(
      Rect.fromCenter(center: center.translate(0, -6), width: 8, height: 8),
      math.pi,
      math.pi,
      false,
      lockPaint,
    );
  }
  
  void _drawParticles(Canvas canvas, Size size) {
    if (masteryPercentage < 80) return; // Only show particles for high mastery
    
    final particlePaint = Paint()
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42);
    
    for (int i = 0; i < 20; i++) {
      final t = (particleAnimation.value + i * 0.05) % 1.0;
      final x = random.nextDouble() * size.width;
      final y = size.height * (1.0 - t);
      
      final opacity = (1.0 - t) * 0.6;
      particlePaint.color = DesignTokens.successGlow.withOpacity(opacity);
      
      canvas.drawCircle(Offset(x, y), 2, particlePaint);
    }
  }
  
  void _drawConstellationName(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Mathematics Journey',
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 24,
          fontWeight: FontWeight.w300,
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final offset = Offset(
      (size.width - textPainter.width) / 2,
      30,
    );
    
    textPainter.paint(canvas, offset);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Data classes for constellation nodes and connections
class ConstellationNode {
  final String id;
  final String label;
  final String subject;
  final Offset position; // Normalized coordinates (0.0 to 1.0)
  final bool isUnlocked;
  final bool isCompleted;
  final double progress; // 0.0 to 1.0
  final List<String> achievements;
  
  const ConstellationNode({
    required this.id,
    required this.label,
    required this.subject,
    required this.position,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.progress = 0.0,
    this.achievements = const [],
  });
}

class ConstellationConnection {
  final String fromNodeId;
  final String toNodeId;
  final bool isUnlocked;
  
  const ConstellationConnection({
    required this.fromNodeId,
    required this.toNodeId,
    this.isUnlocked = false,
  });
}