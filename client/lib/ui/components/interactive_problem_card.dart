import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens.dart';
import '../app_theme.dart';
import 'math_text.dart';

/// Interactive Problem Card - An engaging card for displaying and solving math problems
/// 
/// Features:
/// - Swipe gestures for hints and navigation
/// - Mathematical expression formatting
/// - Real-time answer validation with visual feedback
/// - Animated reveals for solutions and explanations
/// - Accessibility support for screen readers
/// - Contextual help and guidance
class InteractiveProblemCard extends StatefulWidget {
  final Map<String, dynamic> problem;
  final Function(String answer) onAnswer;
  final Function()? onHintRequest;
  final Function()? onSkip;
  final bool showHints;
  final int currentStep;
  final String? currentHint;
  final bool isCorrect;
  final bool isComplete;
  
  const InteractiveProblemCard({
    super.key,
    required this.problem,
    required this.onAnswer,
    this.onHintRequest,
    this.onSkip,
    this.showHints = true,
    this.currentStep = 0,
    this.currentHint,
    this.isCorrect = false,
    this.isComplete = false,
  });

  @override
  State<InteractiveProblemCard> createState() => _InteractiveProblemCardState();
}

class _InteractiveProblemCardState extends State<InteractiveProblemCard>
    with TickerProviderStateMixin {
  
  late AnimationController _shakeController;
  late AnimationController _successController;
  late AnimationController _hintController;
  late AnimationController _typingController;
  
  late Animation<double> _shakeAnimation;
  late Animation<double> _successScaleAnimation;
  late Animation<Color?> _successColorAnimation;
  late Animation<double> _hintSlideAnimation;
  late Animation<double> _typingAnimation;
  
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();
  
  bool _showingHint = false;
  bool _hasAttempted = false;
  String _previousAnswer = '';
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Auto-focus on answer input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _answerFocus.requestFocus();
    });
  }
  
  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _successController = AnimationController(
      duration: DesignTokens.celebration,
      vsync: this,
    );
    
    _hintController = AnimationController(
      duration: DesignTokens.smoothFlow,
      vsync: this,
    );
    
    _typingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));
    
    _successScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.bounceOut,
    ));
    
    _successColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: DesignTokens.successGlow.withOpacity(0.3),
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOut,
    ));
    
    _hintSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hintController,
      curve: Curves.easeOutBack,
    ));
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _shakeController.dispose();
    _successController.dispose();
    _hintController.dispose();
    _typingController.dispose();
    _answerController.dispose();
    _answerFocus.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(InteractiveProblemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle correctness feedback
    if (widget.isCorrect && !oldWidget.isCorrect) {
      _playSuccessAnimation();
      HapticFeedback.mediumImpact();
    } else if (_hasAttempted && !widget.isCorrect && 
               _answerController.text != _previousAnswer) {
      _playShakeAnimation();
      HapticFeedback.lightImpact();
    }
    
    // Handle hint display
    if (widget.currentHint != null && widget.currentHint != oldWidget.currentHint) {
      _showHint();
    }
    
    _previousAnswer = _answerController.text;
  }
  
  void _playSuccessAnimation() {
    _successController.forward().then((_) {
      _successController.reverse();
    });
  }
  
  void _playShakeAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });
  }
  
  void _showHint() {
    setState(() => _showingHint = true);
    _hintController.forward();
  }
  
  void _hideHint() {
    _hintController.reverse().then((_) {
      setState(() => _showingHint = false);
    });
  }
  
  void _submitAnswer() {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;
    
    setState(() => _hasAttempted = true);
    widget.onAnswer(answer);
  }
  
  String get _problemText => widget.problem['problem_text'] ?? '';
  String get _problemTitle => widget.problem['title'] ?? 'Math Problem';
  String get _complexity => widget.problem['complexity'] ?? 'Medium';
  String get _subject => widget.problem['topic'] ?? 'Mathematics';
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _shakeController,
        _successController,
        _hintController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _successScaleAnimation.value,
          child: Transform.translate(
            offset: Offset(
              _shakeAnimation.value * 10 * math.sin(_shakeAnimation.value * math.pi * 8),
              0,
            ),
            child: Container(
              margin: const EdgeInsets.all(DesignTokens.spaceMD),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _successColorAnimation.value ?? Colors.transparent,
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: widget.isCorrect 
                      ? DesignTokens.successGlow
                      : DesignTokens.getSubjectColor(_subject).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Glass(
                radius: DesignTokens.radiusLG,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    _buildProblemContent(),
                    if (_showingHint && widget.currentHint != null) _buildHintSection(),
                    _buildAnswerSection(),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHeader() {
    final subjectColor = DesignTokens.getSubjectColor(_subject);
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMD),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            subjectColor.withOpacity(0.8),
            subjectColor.withOpacity(0.6),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusLG),
          topRight: Radius.circular(DesignTokens.radiusLG),
        ),
      ),
      child: Row(
        children: [
          // Subject badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceSM,
              vertical: DesignTokens.spaceXS,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
            ),
            child: Text(
              _subject,
              style: DesignTokens.captionText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(width: DesignTokens.spaceSM),
          
          // Difficulty indicator
          _buildDifficultyIndicator(),
          
          const Spacer(),
          
          // Step indicator
          if (widget.problem['student_view']?['steps'] != null)
            _buildStepIndicator(),
        ],
      ),
    );
  }
  
  Widget _buildDifficultyIndicator() {
    final difficulty = _complexity.toLowerCase();
    Color difficultyColor;
    IconData difficultyIcon;
    
    switch (difficulty) {
      case 'easy':
        difficultyColor = DesignTokens.successGlow;
        difficultyIcon = Icons.sentiment_very_satisfied_rounded;
        break;
      case 'hard':
        difficultyColor = DesignTokens.errorPulse;
        difficultyIcon = Icons.local_fire_department_rounded;
        break;
      default: // medium
        difficultyColor = DesignTokens.warningAura;
        difficultyIcon = Icons.sentiment_satisfied_rounded;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceXS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: difficultyColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
        border: Border.all(
          color: difficultyColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            difficultyIcon,
            color: difficultyColor,
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            difficulty.toUpperCase(),
            style: TextStyle(
              color: difficultyColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepIndicator() {
    final steps = widget.problem['student_view']?['steps'] as List?;
    if (steps == null || steps.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceXS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
      ),
      child: Text(
        'Step ${widget.currentStep + 1}/${steps.length}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildProblemContent() {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Problem title
          Text(
            _problemTitle,
            style: DesignTokens.sectionTitle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: DesignTokens.spaceMD),
          
          // Problem text with mathematical formatting
          _buildFormattedProblemText(),
        ],
      ),
    );
  }
  
  Widget _buildFormattedProblemText() {
    // Basic mathematical formatting
    // In a real implementation, you'd want a more sophisticated math renderer
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: MathText(
        _problemText,
        style: DesignTokens.problemText.copyWith(
          color: Colors.white,
          height: 1.6,
        ),
      ),
    );
  }
  
  Widget _buildHintSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.5),
        end: Offset.zero,
      ).animate(_hintSlideAnimation),
      child: FadeTransition(
        opacity: _hintSlideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMD),
          padding: const EdgeInsets.all(DesignTokens.spaceMD),
          decoration: BoxDecoration(
            color: DesignTokens.warningAura.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
            border: Border.all(
              color: DesignTokens.warningAura.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: DesignTokens.warningAura,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.spaceSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hint',
                      style: DesignTokens.captionText.copyWith(
                        color: DesignTokens.warningAura,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceXS),
                    MathText(
                      widget.currentHint!,
                      style: DesignTokens.bodyText.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _hideHint,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnswerSection() {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Answer',
            style: DesignTokens.subtitle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: DesignTokens.spaceSM),
          
          TextField(
            controller: _answerController,
            focusNode: _answerFocus,
            style: DesignTokens.answerInput.copyWith(
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Type your answer here...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: BorderSide(
                  color: DesignTokens.getSubjectColor(_subject),
                  width: 2,
                ),
              ),
              suffixIcon: IconButton(
                onPressed: _submitAnswer,
                icon: Icon(
                  Icons.send_rounded,
                  color: DesignTokens.getSubjectColor(_subject),
                ),
              ),
            ),
            onSubmitted: (_) => _submitAnswer(),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceMD),
      child: Row(
        children: [
          // Hint button
          if (widget.showHints && widget.onHintRequest != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onHintRequest,
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: const Text('Get Hint'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignTokens.warningAura,
                  side: BorderSide(
                    color: DesignTokens.warningAura.withOpacity(0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                  ),
                ),
              ),
            ),
          
          if (widget.showHints && widget.onSkip != null)
            const SizedBox(width: DesignTokens.spaceSM),
          
          // Skip button
          if (widget.onSkip != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onSkip,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Skip'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}