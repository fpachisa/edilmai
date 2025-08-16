import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import '../data/learning_modules.dart';
import '../state/game_state.dart';
import 'tutor_screen.dart';
import '../api_client.dart';
import '../config.dart';
import '../auth_service.dart';
import '../state/active_learner.dart';

class SubtopicScreen extends StatefulWidget {
  final String strand;
  final String subStrand;
  final String subTopic;

  const SubtopicScreen({
    super.key,
    required this.strand,
    required this.subStrand,
    required this.subTopic,
  });

  @override
  State<SubtopicScreen> createState() => _SubtopicScreenState();
}

class _SubtopicScreenState extends State<SubtopicScreen> {
  bool _busy = false;
  
  @override
  Widget build(BuildContext context) {
    final modules = getModulesForSubTopic(widget.subStrand, widget.subTopic);
    
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.subStrand,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                widget.subTopic,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with description
                _buildHeader(modules),
                const SizedBox(height: 24),
                
                // Learning path visualization
                if (modules.isNotEmpty) ...[
                  Text(
                    'Learning Path',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildModulesList(modules),
                  ),
                ] else ...[
                  // No modules available - show coming soon
                  Expanded(
                    child: Center(
                      child: _buildComingSoon(),
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

  Widget _buildHeader(List<LearningModule> modules) {
    final totalMinutes = modules.fold<int>(0, (sum, module) => sum + module.estimatedMinutes);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.04),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blueAccent.withOpacity(0.2),
                ),
                child: Icon(
                  _getIconForSubTopic(widget.subTopic),
                  color: Colors.blueAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subTopic,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDescriptionForSubTopic(widget.subTopic),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(
                icon: Icons.access_time_rounded,
                label: '${totalMinutes} mins',
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.psychology_rounded,
                label: '${modules.length} modules',
                color: Colors.purpleAccent,
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.smart_toy_rounded,
                label: 'AI Tutor',
                color: Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModulesList(List<LearningModule> modules) {
    return ListView.separated(
      itemCount: modules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final module = modules[index];
        final isUnlocked = _isModuleUnlocked(module, modules);
        final progress = GameStateController.instance.masteryPercent[module.id] ?? 0.0;
        
        return _ModuleCard(
          module: module,
          isUnlocked: isUnlocked,
          progress: progress,
          onTap: isUnlocked ? () => _startModuleSession(module) : null,
          busy: _busy,
        );
      },
    );
  }

  Widget _buildComingSoon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
          child: const Icon(
            Icons.construction_rounded,
            color: Colors.white60,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Coming Soon!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Learning modules for ${widget.subTopic}\nare being prepared.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context),
          child: const Text('Explore Other Topics'),
        ),
      ],
    );
  }

  bool _isModuleUnlocked(LearningModule module, List<LearningModule> allModules) {
    // First module is always unlocked
    if (module.prerequisites.isEmpty) return true;
    
    // Check if all prerequisites are completed (80%+ mastery)
    for (final prereqId in module.prerequisites) {
      final prereqProgress = GameStateController.instance.masteryPercent[prereqId] ?? 0.0;
      if (prereqProgress < 0.8) return false;
    }
    
    return true;
  }

  Future<void> _startModuleSession(LearningModule module) async {
    if (_busy) return;
    
    setState(() => _busy = true);
    
    try {
      final api = ApiClient(kDefaultApiBase);
      final learnerId = ActiveLearner.instance.id ?? AuthService.getCurrentUserId() ?? 'guest';
      
      // Create a specialized session with AI context for this module
      final sessionData = {
        'learner_id': learnerId,
        'module_id': module.id,
        'module_title': module.title,
        'ai_context': module.aiPromptContext,
        'reference_items': module.referenceItemIds,
        'learning_objectives': module.learningObjectives,
      };
      
      // Start AI tutoring session with module context
      final res = await api.startModuleSession(sessionData: sessionData);
      
      if (!mounted) return;
      
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => TutorScreen(
            apiBase: kDefaultApiBase,
            sessionId: res['session_id'] as String,
            stepId: (res['step_id'] as String?) ?? 's1',
            prompt: (res['prompt'] as String?) ?? "Let's explore ${module.title} together!",
            moduleContext: module,
          ),
          transitionsBuilder: (_, a, __, child) => 
            FadeTransition(opacity: a, child: child),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start learning session: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  IconData _getIconForSubTopic(String subTopic) {
    final topic = subTopic.toLowerCase();
    if (topic.contains('unknowns') || topic.contains('notation')) return Icons.psychology_rounded;
    if (topic.contains('simplify')) return Icons.compress_rounded;
    if (topic.contains('substitution')) return Icons.find_replace_rounded;
    if (topic.contains('equation')) return Icons.balance_rounded;
    return Icons.functions_rounded;
  }

  String _getDescriptionForSubTopic(String subTopic) {
    final topic = subTopic.toLowerCase();
    if (topic.contains('unknowns') || topic.contains('notation')) {
      return 'Learn to work with variables and form algebraic expressions';
    }
    if (topic.contains('simplify')) {
      return 'Master the art of simplifying complex algebraic expressions';
    }
    if (topic.contains('substitution')) {
      return 'Evaluate expressions by substituting values for variables';
    }
    if (topic.contains('equation')) {
      return 'Solve linear equations step by step';
    }
    return 'Explore algebraic concepts with AI guidance';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final LearningModule module;
  final bool isUnlocked;
  final double progress;
  final VoidCallback? onTap;
  final bool busy;

  const _ModuleCard({
    required this.module,
    required this.isUnlocked,
    required this.progress,
    required this.onTap,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor(module.difficulty);
    final isCompleted = progress >= 0.8;
    final isStarted = progress > 0;
    
    return GestureDetector(
      onTap: (isUnlocked && !busy) ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnlocked
                ? [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.04),
                  ]
                : [
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.02),
                  ],
          ),
          border: Border.all(
            color: isCompleted
                ? Colors.greenAccent.withOpacity(0.5)
                : isStarted
                    ? difficultyColor.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
            width: isCompleted || isStarted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isUnlocked
                        ? difficultyColor.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_rounded
                        : isUnlocked
                            ? Icons.psychology_rounded
                            : Icons.lock_rounded,
                    color: isCompleted
                        ? Colors.greenAccent
                        : isUnlocked
                            ? difficultyColor
                            : Colors.white60,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.white60,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        module.difficulty,
                        style: TextStyle(
                          color: isUnlocked ? difficultyColor : Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUnlocked) _buildProgressIndicator(),
              ],
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              module.description,
              style: TextStyle(
                color: isUnlocked ? Colors.white70 : Colors.white.withOpacity(0.4),
                fontSize: 14,
                height: 1.3,
              ),
            ),
            
            if (isUnlocked) ...[
              const SizedBox(height: 16),
              
              // Learning objectives (first 2)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < (module.learningObjectives.length > 2 ? 2 : module.learningObjectives.length); i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              module.learningObjectives[i],
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (module.learningObjectives.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${module.learningObjectives.length - 2} more objectives',
                        style: TextStyle(
                          color: difficultyColor.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Footer
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: Colors.white60,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${module.estimatedMinutes} mins',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: difficultyColor.withOpacity(0.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (busy) ...[
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(difficultyColor),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Starting...',
                            style: TextStyle(
                              color: difficultyColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else ...[
                          Text(
                            isCompleted
                                ? 'Review'
                                : isStarted
                                    ? 'Continue'
                                    : 'Start',
                            style: TextStyle(
                              color: difficultyColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isCompleted
                                ? Icons.refresh_rounded
                                : Icons.arrow_forward_rounded,
                            color: difficultyColor,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              // Locked state
              Row(
                children: [
                  Icon(
                    Icons.lock_rounded,
                    color: Colors.white.withOpacity(0.4),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Complete prerequisites to unlock',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
          ),
          if (progress > 0)
            Container(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(_getDifficultyColor(module.difficulty)),
              ),
            ),
          Center(
            child: progress > 0
                ? Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white60,
                    size: 12,
                  ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.greenAccent;
      case 'advanced':
        return Colors.redAccent;
      default:
        return Colors.blueAccent;
    }
  }
}