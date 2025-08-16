import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens.dart';

/// Achievement Showcase - A rotating trophy display for student accomplishments
/// 
/// Features:
/// - Rotating trophy displays with 3D effects
/// - Unlock animations with celebration effects
/// - Social sharing capabilities
/// - Progress milestone celebrations
/// - Achievement categories and rarity levels
/// - Interactive badge collection
class AchievementShowcase extends StatefulWidget {
  final List<Achievement> achievements;
  final List<Achievement> recentAchievements;
  final Function(Achievement)? onAchievementTap;
  final Function(Achievement)? onShare;
  final bool showUnlockAnimation;
  final Achievement? newAchievement;
  
  const AchievementShowcase({
    super.key,
    required this.achievements,
    this.recentAchievements = const [],
    this.onAchievementTap,
    this.onShare,
    this.showUnlockAnimation = false,
    this.newAchievement,
  });

  @override
  State<AchievementShowcase> createState() => _AchievementShowcaseState();
}

class _AchievementShowcaseState extends State<AchievementShowcase>
    with TickerProviderStateMixin {
  
  late AnimationController _rotationController;
  late AnimationController _unlockController;
  late AnimationController _glowController;
  late AnimationController _floatController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _unlockScaleAnimation;
  late Animation<double> _unlockOpacityAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;
  
  PageController? _pageController;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePageController();
    
    if (widget.showUnlockAnimation && widget.newAchievement != null) {
      _playUnlockAnimation();
    }
  }
  
  void _initializeAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _unlockController = AnimationController(
      duration: DesignTokens.celebration,
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _unlockScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _unlockController,
      curve: Curves.elasticOut,
    ));
    
    _unlockOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _unlockController,
      curve: Curves.easeIn,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _floatAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _initializePageController() {
    if (widget.achievements.isNotEmpty) {
      _pageController = PageController(
        viewportFraction: 0.8,
        initialPage: 0,
      );
    }
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    _unlockController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    _pageController?.dispose();
    super.dispose();
  }
  
  void _playUnlockAnimation() {
    HapticFeedback.mediumImpact();
    _unlockController.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        _unlockController.reverse();
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.achievements.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: DesignTokens.spaceMD),
        _buildAchievementCarousel(),
        const SizedBox(height: DesignTokens.spaceMD),
        _buildRecentAchievements(),
        if (widget.showUnlockAnimation && widget.newAchievement != null)
          _buildUnlockOverlay(),
      ],
    );
  }
  
  Widget _buildHeader() {
    final completedCount = widget.achievements.where((a) => a.isUnlocked).length;
    final totalCount = widget.achievements.length;
    final completionRate = totalCount > 0 ? completedCount / totalCount : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMD),
      decoration: BoxDecoration(
        gradient: DesignTokens.primaryGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: DesignTokens.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Achievements',
                  style: DesignTokens.sectionTitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$completedCount of $totalCount unlocked',
                  style: DesignTokens.bodyText.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          _buildCompletionRing(completionRate),
        ],
      ),
    );
  }
  
  Widget _buildCompletionRing(double progress) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          // Background ring
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.2)),
            backgroundColor: Colors.transparent,
          ),
          // Progress ring
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(
                  Colors.white.withOpacity(_glowAnimation.value),
                ),
                backgroundColor: Colors.transparent,
              );
            },
          ),
          // Percentage text
          Center(
            child: Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAchievementCarousel() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: widget.achievements.length,
        itemBuilder: (context, index) {
          final achievement = widget.achievements[index];
          final isCenter = index == _currentPage;
          
          return AnimatedBuilder(
            animation: Listenable.merge([
              _rotationController,
              _glowController,
              _floatController,
            ]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, isCenter ? _floatAnimation.value : 0),
                child: Transform.scale(
                  scale: isCenter ? 1.0 : 0.8,
                  child: _buildAchievementCard(achievement, isCenter),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildAchievementCard(Achievement achievement, bool isCenter) {
    return GestureDetector(
      onTap: () => widget.onAchievementTap?.call(achievement),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSM),
        constraints: const BoxConstraints(
          minHeight: 150,
          maxHeight: 170,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
          gradient: achievement.isUnlocked 
              ? _getAchievementGradient(achievement.rarity)
              : LinearGradient(
                  colors: [
                    Colors.grey.shade700,
                    Colors.grey.shade800,
                  ],
                ),
          boxShadow: achievement.isUnlocked && isCenter
              ? [
                  BoxShadow(
                    color: _getAchievementColor(achievement.rarity).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Background pattern
            if (achievement.isUnlocked) _buildAchievementPattern(achievement),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceMD),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Achievement icon with rotation
                  Transform.rotate(
                    angle: achievement.isUnlocked && isCenter 
                        ? _rotationAnimation.value * 0.1 
                        : 0,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: achievement.isUnlocked 
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        achievement.icon,
                        size: 40,
                        color: achievement.isUnlocked 
                            ? Colors.white
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: DesignTokens.spaceMD),
                  
                  // Achievement name
                  Flexible(
                    child: Text(
                      achievement.name,
                      style: DesignTokens.subtitle.copyWith(
                        color: achievement.isUnlocked 
                            ? Colors.white
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: DesignTokens.spaceXS),
                  
                  // Achievement description
                  Flexible(
                    child: Text(
                      achievement.description,
                      style: DesignTokens.captionText.copyWith(
                        color: achievement.isUnlocked 
                            ? Colors.white.withOpacity(0.9)
                            : Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: DesignTokens.spaceSM),
                  
                  // Rarity indicator
                  _buildRarityIndicator(achievement.rarity),
                ],
              ),
            ),
            
            // Lock overlay
            if (!achievement.isUnlocked) _buildLockOverlay(),
            
            // Share button
            if (achievement.isUnlocked)
              Positioned(
                top: DesignTokens.spaceSM,
                right: DesignTokens.spaceSM,
                child: IconButton(
                  onPressed: () => widget.onShare?.call(achievement),
                  icon: const Icon(
                    Icons.share_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAchievementPattern(Achievement achievement) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _AchievementPatternPainter(
          rarity: achievement.rarity,
          animation: _rotationAnimation,
        ),
      ),
    );
  }
  
  Widget _buildRarityIndicator(AchievementRarity rarity) {
    final color = _getAchievementColor(rarity);
    final stars = _getRarityStars(rarity);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => Icon(
          index < stars ? Icons.star_rounded : Icons.star_border_rounded,
          color: color,
          size: 16,
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
  
  Widget _buildRecentAchievements() {
    if (widget.recentAchievements.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMD),
          child: Text(
            'Recently Earned',
            style: DesignTokens.sectionTitle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spaceSM),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMD),
            itemCount: widget.recentAchievements.length,
            itemBuilder: (context, index) {
              final achievement = widget.recentAchievements[index];
              return _buildRecentAchievementBadge(achievement);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentAchievementBadge(Achievement achievement) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(right: DesignTokens.spaceSM),
      decoration: BoxDecoration(
        gradient: _getAchievementGradient(achievement.rarity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getAchievementColor(achievement.rarity).withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        achievement.icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }
  
  Widget _buildUnlockOverlay() {
    if (widget.newAchievement == null) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _unlockController,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.8 * _unlockOpacityAnimation.value),
            child: Center(
              child: Transform.scale(
                scale: _unlockScaleAnimation.value,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: _getAchievementGradient(widget.newAchievement!.rarity),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: _getAchievementColor(widget.newAchievement!.rarity)
                            .withOpacity(0.6),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Achievement Unlocked!',
                        style: DesignTokens.sectionTitle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceLG),
                      Icon(
                        widget.newAchievement!.icon,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: DesignTokens.spaceLG),
                      Text(
                        widget.newAchievement!.name,
                        style: DesignTokens.subtitle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DesignTokens.spaceSM),
                      _buildRarityIndicator(widget.newAchievement!.rarity),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceXL),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 60,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: DesignTokens.spaceMD),
          Text(
            'No Achievements Yet',
            style: DesignTokens.sectionTitle.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: DesignTokens.spaceSM),
          Text(
            'Start solving problems to earn your first achievement!',
            style: DesignTokens.bodyText.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  LinearGradient _getAchievementGradient(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return const LinearGradient(
          colors: [Color(0xFF6B73FF), Color(0xFF9571FF)],
        );
      case AchievementRarity.rare:
        return const LinearGradient(
          colors: [Color(0xFF00D4FF), Color(0xFF5B85FF)],
        );
      case AchievementRarity.epic:
        return const LinearGradient(
          colors: [Color(0xFFFFB76B), Color(0xFFFF9068)],
        );
      case AchievementRarity.legendary:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
        );
    }
  }
  
  Color _getAchievementColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return const Color(0xFF6B73FF);
      case AchievementRarity.rare:
        return const Color(0xFF00D4FF);
      case AchievementRarity.epic:
        return const Color(0xFFFFB76B);
      case AchievementRarity.legendary:
        return const Color(0xFFFFD700);
    }
  }
  
  int _getRarityStars(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 1;
      case AchievementRarity.rare:
        return 2;
      case AchievementRarity.epic:
        return 4;
      case AchievementRarity.legendary:
        return 5;
    }
  }
}

/// Custom painter for achievement background patterns
class _AchievementPatternPainter extends CustomPainter {
  final AchievementRarity rarity;
  final Animation<double> animation;
  
  _AchievementPatternPainter({
    required this.rarity,
    required this.animation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    switch (rarity) {
      case AchievementRarity.legendary:
        _drawLegendaryPattern(canvas, size, paint);
        break;
      case AchievementRarity.epic:
        _drawEpicPattern(canvas, size, paint);
        break;
      case AchievementRarity.rare:
        _drawRarePattern(canvas, size, paint);
        break;
      case AchievementRarity.common:
        _drawCommonPattern(canvas, size, paint);
        break;
    }
  }
  
  void _drawLegendaryPattern(Canvas canvas, Size size, Paint paint) {
    // Draw radiating lines from center
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;
    
    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi / 6) + (animation.value * math.pi / 6);
      final start = Offset(
        center.dx + math.cos(angle) * (radius * 0.5),
        center.dy + math.sin(angle) * (radius * 0.5),
      );
      final end = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      
      canvas.drawLine(start, end, paint);
    }
  }
  
  void _drawEpicPattern(Canvas canvas, Size size, Paint paint) {
    // Draw hexagonal pattern
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4;
    
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) + (animation.value * math.pi / 12);
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawRarePattern(Canvas canvas, Size size, Paint paint) {
    // Draw concentric circles
    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 1; i <= 3; i++) {
      final radius = (size.width / 6) * i;
      canvas.drawCircle(center, radius, paint);
    }
  }
  
  void _drawCommonPattern(Canvas canvas, Size size, Paint paint) {
    // Draw simple corner decorations
    final cornerSize = size.width / 8;
    
    // Top left
    canvas.drawLine(
      Offset(cornerSize, cornerSize),
      Offset(cornerSize * 2, cornerSize),
      paint,
    );
    canvas.drawLine(
      Offset(cornerSize, cornerSize),
      Offset(cornerSize, cornerSize * 2),
      paint,
    );
    
    // Top right
    canvas.drawLine(
      Offset(size.width - cornerSize, cornerSize),
      Offset(size.width - cornerSize * 2, cornerSize),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - cornerSize, cornerSize),
      Offset(size.width - cornerSize, cornerSize * 2),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Achievement data model
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final AchievementRarity rarity;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String category;
  final int xpReward;
  
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.category,
    this.xpReward = 0,
  });
}

/// Achievement rarity levels
enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}