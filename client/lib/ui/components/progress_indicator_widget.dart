import 'package:flutter/material.dart';
import '../../services/progress_tracking_service.dart';

/// Widget that displays real-time learning progress
class ProgressIndicatorWidget extends StatefulWidget {
  final String topic;
  final bool showDetailed;
  
  const ProgressIndicatorWidget({
    super.key,
    required this.topic,
    this.showDetailed = false,
  });

  @override
  State<ProgressIndicatorWidget> createState() => _ProgressIndicatorWidgetState();
}

class _ProgressIndicatorWidgetState extends State<ProgressIndicatorWidget> {
  final ProgressTrackingService _progressService = ProgressTrackingService();
  ProgressSnapshot? _currentProgress;

  @override
  void initState() {
    super.initState();
    _initializeProgress();
  }

  Future<void> _initializeProgress() async {
    await _progressService.initialize();
    _currentProgress = _progressService.currentProgress;
    if (mounted) setState(() {});
    
    // Listen to real-time progress updates
    _progressService.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _currentProgress = progress;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentProgress == null) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final topicSummary = _progressService.getTopicSummary(widget.topic);
    final sessionsCompleted = topicSummary['sessionsCompleted'] as int;
    final overallAccuracy = topicSummary['overallAccuracy'] as double;
    final lastAccessed = topicSummary['lastAccessed'] as DateTime?;

    if (widget.showDetailed) {
      return _buildDetailedProgress(sessionsCompleted, overallAccuracy, lastAccessed);
    } else {
      return _buildCompactProgress(sessionsCompleted, overallAccuracy);
    }
  }

  Widget _buildCompactProgress(int sessions, double accuracy) {
    final theme = Theme.of(context);
    final progress = (accuracy * 100).clamp(0.0, 100.0);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sessions > 0 ? Icons.trending_up : Icons.play_circle_outline,
            size: 16,
            color: _getProgressColor(progress),
          ),
          const SizedBox(width: 4),
          Text(
            sessions > 0 ? '${progress.round()}%' : 'Start',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getProgressColor(progress),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedProgress(int sessions, double accuracy, DateTime? lastAccessed) {
    final theme = Theme.of(context);
    final progress = (accuracy * 100).clamp(0.0, 100.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.topic} Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: accuracy,
                    backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(_getProgressColor(progress)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${progress.round()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getProgressColor(progress),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatChip(
                icon: Icons.check_circle_outline,
                label: '$sessions Sessions',
                color: theme.colorScheme.primary,
              ),
              _buildStatChip(
                icon: Icons.insights,
                label: '${_currentProgress!.totalStepsCompleted} Steps',
                color: theme.colorScheme.secondary,
              ),
            ],
          ),
          
          // Last accessed
          if (lastAccessed != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last active: ${_formatLastAccessed(lastAccessed)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) return Colors.green;
    if (progress >= 60) return Colors.orange;
    if (progress >= 40) return Colors.yellow.shade700;
    return Colors.grey;
  }

  String _formatLastAccessed(DateTime lastAccessed) {
    final now = DateTime.now();
    final difference = now.difference(lastAccessed);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastAccessed.month}/${lastAccessed.day}';
    }
  }
}

/// Animated progress indicator for session completion
class SessionProgressIndicator extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final double accuracy;
  
  const SessionProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.accuracy,
  });

  @override
  State<SessionProgressIndicator> createState() => _SessionProgressIndicatorState();
}

class _SessionProgressIndicatorState extends State<SessionProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.currentStep / widget.totalSteps,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void didUpdateWidget(SessionProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.currentStep / widget.totalSteps,
        end: widget.currentStep / widget.totalSteps,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Session Progress',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.currentStep}/${widget.totalSteps}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                minHeight: 4,
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Accuracy: ${(widget.accuracy * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getAccuracyColor(widget.accuracy),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.currentStep == widget.totalSteps)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Complete!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }
}