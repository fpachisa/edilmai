import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import '../data/learning_path_loader.dart';
import '../data/problem_loader.dart';
import '../state/game_state.dart';
import 'tutor_screen.dart';
import '../api_client.dart';
import '../config.dart';
import '../auth_service.dart';
import '../state/active_learner.dart';

class LearningPathScreen extends StatefulWidget {
  final String pathId;

  const LearningPathScreen({
    super.key,
    required this.pathId,
  });

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  LearningPath? _learningPath;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadPath();
  }

  Future<void> _loadPath() async {
    final path = await LearningPathLoader.loadPath(widget.pathId);
    setState(() {
      _learningPath = path;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AnimatedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (_learningPath == null) {
      return AnimatedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: const Center(
            child: Text(
              'Learning path not found',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _learningPath!.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: GameStateController.instance,
            builder: (context, _) {
              final progress = GameStateController.instance.masteryPercent;
              final nextModule = getNextModule(_learningPath!.modules, progress);
              
              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(nextModule),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  
                  // Learning Path Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Text(
                            'Learning Path',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  
                  // Modules List
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final module = _learningPath!.modules[index];
                          final moduleProgress = progress[module.id] ?? 0.0;
                          final isUnlocked = isModuleUnlocked(module, progress);
                          final isNext = nextModule?.id == module.id;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 600),
                                child: _ModuleProgressCard(
                                  module: module,
                                  progress: moduleProgress,
                                  isUnlocked: isUnlocked,
                                  isNext: isNext,
                                  moduleIndex: index + 1,
                                  onTap: isUnlocked 
                                      ? () => _startModule(module)
                                      : null,
                                  busy: _busy,
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _learningPath!.modules.length,
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LearningPathModule? nextModule) {
    final progress = GameStateController.instance.masteryPercent;
    final completedCount = _learningPath!.modules
        .where((m) => (progress[m.id] ?? 0.0) >= 0.8)
        .length;
    final totalCount = _learningPath!.modules.length;
    final overallProgress = totalCount > 0 ? completedCount / totalCount : 0.0;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.blueAccent.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.functions_rounded,
                    color: Colors.blueAccent,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _learningPath!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _learningPath!.title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Progress bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.white.withOpacity(0.2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: overallProgress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Text(
                  '$completedCount / $totalCount modules completed',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(overallProgress * 100).round()}%',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            
            if (nextModule != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Continue Learning',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            nextModule.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : () => _startModule(nextModule),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: _busy 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Start',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startModule(LearningPathModule module) async {
    if (_busy) return;
    
    setState(() => _busy = true);
    
    try {
      final api = ApiClient(kDefaultApiBase);
      final learnerId = ActiveLearner.instance.id ?? AuthService.getCurrentUserId() ?? 'guest';
      
      // Use backend AI tutoring with module context
      final res = await api.startAdaptiveSession(
        learnerId: learnerId,
        itemId: module.id,
      );
      
      if (!mounted) return;
      
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => TutorScreen(
            apiBase: kDefaultApiBase,
            sessionId: res['session_id'] as String,
            stepId: (res['step_id'] as String?) ?? 's1',
            prompt: (res['prompt'] as String?) ?? "Let's explore ${module.title} together!",
            moduleContext: null, // Will be handled by API with item context
          ),
          transitionsBuilder: (_, a, __, child) => 
            FadeTransition(opacity: a, child: child),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showAIErrorDialog(module, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  
  void _showAIErrorDialog(LearningPathModule module, Object error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2139),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('AI Tutor Connection Failed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Unable to connect to the AI tutoring system for "${module.title}".\n\n'
          'This app requires a live AI connection to provide personalized tutoring. '
          'Please check your internet connection and try again.\n\n'
          'Technical details: $error',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again Later', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showComingSoonDialog(LearningPathModule module) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2139),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent,
                    Colors.blueAccent.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                module.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.rocket_launch_rounded,
                    size: 48,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    module.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    module.title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Interactive problems coming soon.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blueAccent,
            ),
            child: const Text('Can\'t wait!'),
          ),
        ],
      ),
    );
  }

}

class _ModuleProgressCard extends StatelessWidget {
  final LearningPathModule module;
  final double progress;
  final bool isUnlocked;
  final bool isNext;
  final int moduleIndex;
  final VoidCallback? onTap;
  final bool busy;

  const _ModuleProgressCard({
    required this.module,
    required this.progress,
    required this.isUnlocked,
    required this.isNext,
    required this.moduleIndex,
    required this.onTap,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress >= 0.8;
    final isStarted = progress > 0;
    
    return GestureDetector(
      onTap: (isUnlocked && !busy) ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnlocked
                ? [
                    Colors.white.withOpacity(isNext ? 0.15 : 0.12),
                    Colors.white.withOpacity(isNext ? 0.08 : 0.04),
                  ]
                : [
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.02),
                  ],
          ),
          border: Border.all(
            color: isCompleted
                ? Colors.greenAccent.withOpacity(0.5)
                : isNext
                    ? Colors.blueAccent.withOpacity(0.5)
                    : isStarted
                        ? Colors.blueAccent.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
            width: isCompleted || isNext || isStarted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Module number and progress indicator
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Colors.greenAccent
                          : isNext
                              ? Colors.blueAccent
                              : isUnlocked
                                  ? Colors.blueAccent.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.1),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : Text(
                              '$moduleIndex',
                              style: TextStyle(
                                color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.5),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  if (isStarted && !isCompleted) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Module content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            module.title,
                            style: TextStyle(
                              color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.6),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (isNext)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.blueAccent.withOpacity(0.2),
                            ),
                            child: const Text(
                              'NEXT',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor() {
    return Colors.blueAccent;
  }
}

/// REAL tutor that loads actual problems from JSON files
class _RealTutorScreen extends StatefulWidget {
  final LearningPathModule module;
  final String pathId; // e.g., 'fractions', 'algebra'

  const _RealTutorScreen({
    required this.module,
    required this.pathId,
  });

  @override
  State<_RealTutorScreen> createState() => _RealTutorScreenState();
}

class _RealTutorScreenState extends State<_RealTutorScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  
  List<Problem> _problems = [];
  int _currentProblemIndex = 0;
  bool _loading = true;
  String? _error;
  
  Problem? get _currentProblem => 
      _problems.isNotEmpty ? _problems[_currentProblemIndex] : null;
  
  @override
  void initState() {
    super.initState();
    _loadProblems();
  }
  
  Future<void> _loadProblems() async {
    try {
      // Load problems based on module's reference item IDs
      final problems = <Problem>[];
      
      final problem = await ProblemLoader.getProblemById(widget.module.id);
      if (problem != null) {
        problems.add(problem);
      }
      
      if (problems.isEmpty) {
        // Fallback: load all problems for the selected learning path
        final topic = widget.pathId; // Use the pathId (e.g., 'fractions') instead of parsing module ID
        problems.addAll(await ProblemLoader.loadProblems(topic));
      }
      
      setState(() {
        _problems = problems;
        _loading = false;
        if (_problems.isNotEmpty) {
          _startCurrentProblem();
        } else {
          _error = 'No problems found for this module';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading problems: $e';
        _loading = false;
      });
    }
  }
  
  void _startCurrentProblem() {
    final problem = _currentProblem;
    if (problem == null) return;
    
    _messages.clear();
    
    _messages.add({
      'role': 'tutor',
      'content': '📚 ${problem.title}\n\n${problem.problemText}',
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    
    final userMessage = _controller.text.trim();
    final problem = _currentProblem;
    if (problem == null) return;
    
    _controller.clear();
    
    setState(() {
      _messages.add({'role': 'student', 'content': userMessage});
      
      // Simple local evaluation for testing
      if (_isAnswerAcceptable(userMessage, problem)) {
        _messages.add({
          'role': 'tutor',
          'content': '🎉 Excellent! That\'s correct!',
        });
        // Move to next problem after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _advanceToNextProblem();
          });
        });
      } else {
        // Give a hint
        final attemptNumber = _messages.where((m) => m['role'] == 'student').length;
        _giveHint(problem, attemptNumber);
      }
    });
  }
  
  bool _isAnswerAcceptable(String answer, Problem problem) {
    final cleanAnswer = answer.toLowerCase().trim();
    
    // Check correct answer
    if (cleanAnswer == problem.answerDetails.correctAnswer.toLowerCase().trim()) {
      return true;
    }
    
    // Check alternative answers
    for (final acceptable in problem.answerDetails.alternativeAnswers) {
      if (cleanAnswer == acceptable.toLowerCase().trim()) {
        return true;
      }
    }
    
    // For expression format, be more flexible with spacing and order
    if (problem.answerDetails.answerFormat == 'expression') {
      final userClean = cleanAnswer.replaceAll(' ', '');
      final correctClean = problem.answerDetails.correctAnswer.toLowerCase().replaceAll(' ', '');
      if (userClean == correctClean) {
        return true;
      }
      
      // Check alternative formats without spaces
      for (final acceptable in problem.answerDetails.alternativeAnswers) {
        final acceptableClean = acceptable.toLowerCase().replaceAll(' ', '');
        if (userClean == acceptableClean) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  void _giveHint(Problem problem, int attemptNumber) {
    final hints = problem.aiGuidance.hints;
    String hint = 'Let me give you a hint...';
    
    // Find appropriate hint based on attempt number
    final hintIndex = attemptNumber.clamp(1, hints.length) - 1;
    if (hintIndex < hints.length) {
      hint = hints[hintIndex].hintText;
    }
    
    _messages.add({
      'role': 'tutor',
      'content': '💡 $hint',
    });
  }
  
  void _advanceToNextProblem() {
    if (_currentProblemIndex < _problems.length - 1) {
      // Move to next problem
      _currentProblemIndex++;
      _startCurrentProblem();
      _messages.add({
        'role': 'tutor',
        'content': '🎉 Great job! Let\'s try the next problem.',
      });
    } else {
      // All problems completed!
      _messages.add({
        'role': 'tutor',
        'content': '🌟 Outstanding work! You\'ve completed all the problems in this module. You\'ve shown excellent understanding of ${widget.module.title}!',
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E27),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E27),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.module.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Problem ${_currentProblemIndex + 1} of ${_problems.length}',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _problems.isNotEmpty 
                      ? (_currentProblemIndex + 1) / _problems.length
                      : 0,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isStudent = message['role'] == 'student';
                
                return Align(
                  alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: isStudent 
                          ? Colors.blueAccent.withOpacity(0.8)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message['content']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your answer...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
