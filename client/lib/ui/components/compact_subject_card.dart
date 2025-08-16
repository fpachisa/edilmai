import 'package:flutter/material.dart';
import '../design_tokens.dart';

class CompactSubjectCard extends StatefulWidget {
  final String subject;
  final String displayName;
  final int completedProblems;
  final int totalProblems;
  final double masteryPercentage;
  final VoidCallback onTap;
  final bool isLocked;

  const CompactSubjectCard({
    super.key,
    required this.subject,
    required this.displayName,
    required this.completedProblems,
    required this.totalProblems,
    required this.masteryPercentage,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  State<CompactSubjectCard> createState() => _CompactSubjectCardState();
}

class _CompactSubjectCardState extends State<CompactSubjectCard> {
  bool _isHovered = false;

  String _getSubjectEmoji() {
    switch (widget.subject.toLowerCase()) {
      case 'algebra': return '🔮';
      case 'fractions': return '🍰';
      case 'geometry': return '🏛️';
      case 'speed': return '⚡';
      case 'ratio': return '⚖️';
      case 'percentage': return '📊';
      case 'data-analysis': return '📈';
      case 'measurement': return '📏';
      default: return '🧮';
    }
  }

  Color _getSubjectColor() {
    switch (widget.subject.toLowerCase()) {
      case 'algebra': return DesignTokens.algebraMystic;
      case 'fractions': return DesignTokens.fractionForest;
      case 'speed': return DesignTokens.speedStorm;
      case 'ratio': return DesignTokens.ratioRealm;
      case 'measurement': return DesignTokens.geometryGalaxy;
      case 'data-analysis': return DesignTokens.statisticsSpace;
      case 'percentage': return DesignTokens.percentagePlanet;
      case 'geometry': return DesignTokens.geometryGalaxy;
      default: return DesignTokens.primaryMagic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSubjectColor();
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    // Responsive sizing
    final emojiSize = isTablet ? 32.0 : 16.0;
    final titleSize = isTablet ? 18.0 : 9.0;
    final progressSize = isTablet ? 12.0 : 8.0;
    final padding = isTablet ? 14.0 : 8.0;
    final borderRadius = isTablet ? 12.0 : 8.0;
    final spacing = isTablet ? 6.0 : 3.0;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isLocked ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: widget.isLocked 
                ? LinearGradient(
                    colors: [
                      Colors.grey.shade600,
                      Colors.grey.shade700,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.8),
                      color.withOpacity(0.6),
                    ],
                  ),
            boxShadow: [
              BoxShadow(
                color: widget.isLocked 
                    ? Colors.black26
                    : color.withOpacity(0.2),
                blurRadius: _isHovered ? 8 : 4,
                offset: Offset(0, _isHovered ? 3 : 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Emoji
                Text(
                  _getSubjectEmoji(),
                  style: TextStyle(fontSize: emojiSize),
                ),
                
                SizedBox(height: spacing),
                
                // Subject name
                Text(
                  widget.displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: titleSize,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: spacing - 1),
                
                // Progress
                if (!widget.isLocked) ...[
                  Text(
                    '${widget.masteryPercentage.toInt()}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      fontSize: progressSize,
                    ),
                  ),
                  SizedBox(height: spacing - 1),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: widget.masteryPercentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ] else
                  Text(
                    'Locked',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: progressSize,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}