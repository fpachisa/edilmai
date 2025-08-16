import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_client.dart';
import '../config.dart';
import 'tutor_screen.dart';
import '../ui/app_theme.dart';
import '../ui/design_tokens.dart';
import '../ui/components/compact_subject_card.dart';
import '../ui/components/progress_constellation.dart';
import '../ui/components/achievement_showcase.dart';
import '../ui/components/interactive_problem_card.dart';
import '../state/game_state.dart';
import '../auth_service.dart';
import '../state/active_learner.dart';
import 'learning_path_screen.dart';

/// Enhanced Home Screen - A beautiful, engaging dashboard for student learning
/// 
/// Features:
/// - Subject island cards with 3D effects and progress visualization
/// - Progress constellation showing learning journey
/// - Achievement showcase with unlock animations
/// - Personalized recommendations
/// - Quick access to continue learning
/// - Beautiful animations and micro-interactions
class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  
  bool _busy = false;
  Map<String, dynamic>? _feed;
  bool _loadingFeed = true;
  String? _feedError;
  Map<String, SubjectData> _subjects = {};
  List<dynamic> _centralizedTopics = [];
  int _currentXP = 0;
  int _currentLevel = 1;
  int _streakDays = 0;
  
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardAnimation;
  
  final ScrollController _scrollController = ScrollController();
  
  /// Educational philosophy: ALL subjects should be unlocked for exploration!
  /// Students learn best when they can follow their curiosity and interests.
  bool _isSubjectUnlocked(String subjectKey, Map<String, SubjectData> allSubjects) {
    // 🎓 EDUCATIONAL BEST PRACTICE: Always allow exploration and discovery!
    // Locking content creates barriers to learning and kills natural curiosity.
    return true;
  }
  
  List<Achievement> _achievements = [];
  
  List<Achievement> _generateAchievements() {
    final achievements = <Achievement>[];
    
    // Learning milestones
    achievements.add(Achievement(
      id: 'first_problem',
      name: 'First Steps',
      description: 'Solved your first problem',
      icon: Icons.school_rounded,
      rarity: AchievementRarity.common,
      isUnlocked: _currentXP > 0,
      category: 'Learning',
      xpReward: 10,
    ));
    
    // XP-based achievements
    achievements.add(Achievement(
      id: 'xp_100',
      name: 'Rising Star',
      description: 'Earned 100 XP',
      icon: Icons.star_rounded,
      rarity: AchievementRarity.common,
      isUnlocked: _currentXP >= 100,
      category: 'Progress',
      xpReward: 25,
    ));
    
    achievements.add(Achievement(
      id: 'xp_500',
      name: 'Math Champion',
      description: 'Earned 500 XP',
      icon: Icons.emoji_events_rounded,
      rarity: AchievementRarity.rare,
      isUnlocked: _currentXP >= 500,
      category: 'Progress',
      xpReward: 100,
    ));
    
    // Streak achievements
    achievements.add(Achievement(
      id: 'streak_3',
      name: 'Consistency',
      description: '3-day learning streak',
      icon: Icons.local_fire_department_rounded,
      rarity: AchievementRarity.common,
      isUnlocked: _streakDays >= 3,
      category: 'Habit',
      xpReward: 25,
    ));
    
    achievements.add(Achievement(
      id: 'streak_7',
      name: 'Dedication',
      description: '7-day learning streak',
      icon: Icons.whatshot_rounded,
      rarity: AchievementRarity.rare,
      isUnlocked: _streakDays >= 7,
      category: 'Habit',
      xpReward: 75,
    ));
    
    // Subject mastery achievements
    for (final subject in _subjects.entries) {
      if (subject.value.masteryPercentage >= 80) {
        achievements.add(Achievement(
          id: '${subject.key}_master',
          name: '${subject.value.displayName} Master',
          description: 'Achieved 80% mastery in ${subject.value.displayName}',
          icon: Icons.workspace_premium_rounded,
          rarity: AchievementRarity.epic,
          isUnlocked: true,
          category: 'Mastery',
          xpReward: 200,
        ));
      }
    }
    
    return achievements;
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGameState();
    _loadFeed();
  }
  
  Future<void> _initializeGameState() async {
    // Load game state first to get current progress
    await GameStateController.instance.load();
    
    // Load centralized topics
    await _loadCentralizedTopics();
    
    if (mounted) {
      setState(() {
        _currentXP = GameStateController.instance.xp;
        _currentLevel = (_currentXP / 100).floor() + 1;
        _streakDays = GameStateController.instance.streakDays;
        
        // Load subject progress from mastery data using centralized topics
        final masteryData = GameStateController.instance.masteryPercent;
        _subjects = {
          for (final topic in _centralizedTopics)
            topic['id']: SubjectData(
              key: topic['id'],
              displayName: topic['display_name'],
              completedProblems: ((masteryData[topic['id']] ?? 0.0) * _getSubjectProblemCount(topic['id'])).round(),
              totalProblems: _getSubjectProblemCount(topic['id']),
              masteryPercentage: (masteryData[topic['id']] ?? 0.0) * 100,
              isLocked: false,
              recentAchievements: [],
            ),
        };
        
        // Generate achievements based on current state
        _achievements = _generateAchievements();
      });
    }
  }
  
  Future<void> _loadCentralizedTopics() async {
    try {
      final jsonString = await rootBundle.loadString('assets/p6_maths_topics.json');
      final topicsData = json.decode(jsonString);
      _centralizedTopics = topicsData['subjects'] ?? [];
    } catch (e) {
      print('Error loading centralized topics: $e');
      _centralizedTopics = [];
    }
  }
  
  int _getSubjectProblemCount(String subjectKey) {
    // Rough estimates based on curriculum content
    switch (subjectKey) {
      case 'algebra': return 60;
      case 'fractions': return 80;
      case 'speed': return 40;
      case 'ratio': return 45;
      case 'measurement': return 70;
      case 'data-analysis': return 35;
      case 'percentage': return 50;
      case 'geometry': return 55;
      default: return 50;
    }
  }
  
  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: DesignTokens.dramaticReveal,
      vsync: this,
    );
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    // Skip backend API call - use only centralized topics
    setState(() {
      _loadingFeed = true;
      _feedError = null;
    });
    try {
      // Topics are already loaded in _initializeGameState - just complete the loading
      setState(() {
        _loadingFeed = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedError = 'Could not load topics. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loadingFeed = false);
    }
  }

  void _navigateToSubject(String subjectKey) {
    if (_subjects[subjectKey]?.isLocked == true) {
      _showLockedSubjectDialog(subjectKey);
      return;
    }
    
    // First try LearningPathScreen, fallback to TutorScreen if needed
    try {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => LearningPathScreen(
            pathId: subjectKey,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (e) {
      // Fallback: show coming soon
      _showComingSoonDialog(subjectKey);
    }
  }

  void _showLockedSubjectDialog(String subjectKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2139),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🔒 Subject Locked', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Keep learning to unlock ${_subjects[subjectKey]?.displayName ?? subjectKey}! Complete more problems in other subjects to progress.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String subjectKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2139),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🚀 Coming Soon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          '${_subjects[subjectKey]?.displayName ?? subjectKey} content is being prepared with love! Check back soon for an amazing learning experience.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _loadingFeed
            ? _buildLoadingState()
            : _feedError != null
                ? _buildErrorState()
                : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading your learning journey...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.white70,
            ),
            const SizedBox(height: 16),
            Text(
              _feedError ?? 'Something went wrong',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loadFeed,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildAnimatedHeader(),
        _buildWelcomeSection(),
        _buildQuickStatsSection(),
        _buildSubjectGridSection(),
        _buildAchievementSection(),
        _buildRecommendationsSection(),
        const SliverToBoxAdapter(
          child: SizedBox(height: DesignTokens.spaceXXL),
        ),
      ],
    );
  }

  Widget _buildAnimatedHeader() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _headerAnimation,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spaceLG,
            DesignTokens.spaceSM,
            DesignTokens.spaceLG,
            DesignTokens.spaceXS,
          ),
          child: Text(
            'Welcome back!',
            style: DesignTokens.heroTitle.copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _headerAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLG),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spaceSM),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.stars_rounded,
                    label: 'XP',
                    value: _currentXP.toString(),
                    color: DesignTokens.primaryMagic,
                  ),
                ),
                Container(
                  width: 1,
                  height: 25,
                  color: Colors.white.withOpacity(0.15),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streak',
                    value: '$_streakDays days',
                    color: DesignTokens.warningAura,
                  ),
                ),
                Container(
                  width: 1,
                  height: 25,
                  color: Colors.white.withOpacity(0.15),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Level',
                    value: _currentLevel.toString(),
                    color: DesignTokens.successGlow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 14,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectGridSection() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _cardAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLG, vertical: DesignTokens.spaceSM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Your Adventure',
                style: DesignTokens.sectionTitle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceSM),
              AnimatedBuilder(
                animation: _cardAnimation,
                builder: (context, child) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
                      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.0 : 0.9,
                      crossAxisSpacing: MediaQuery.of(context).size.width > 600 ? 16 : 8,
                      mainAxisSpacing: MediaQuery.of(context).size.width > 600 ? 16 : 8,
                    ),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subjects = _subjects.values.toList();
                      final subject = subjects[index];
                      
                      return Transform.translate(
                        offset: Offset(
                          0,
                          (1 - _cardAnimation.value) * 50 * (index % 2 == 0 ? 1 : -1),
                        ),
                        child: Opacity(
                          opacity: _cardAnimation.value,
                          child: CompactSubjectCard(
                            subject: subject.key,
                            displayName: subject.displayName,
                            completedProblems: subject.completedProblems,
                            totalProblems: subject.totalProblems,
                            masteryPercentage: subject.masteryPercentage,
                            onTap: () => _navigateToSubject(subject.key),
                            isLocked: subject.isLocked,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForSubject(String subjectKey) {
    switch (subjectKey) {
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

  Widget _buildAchievementSection() {
    final unlockedAchievements = _achievements.where((a) => a.isUnlocked).take(2).toList();
    if (unlockedAchievements.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _cardAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Achievements',
                style: DesignTokens.sectionTitle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceSM),
              AchievementShowcase(
                achievements: unlockedAchievements,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _cardAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLG),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spaceMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.white70,
                  size: 24,
                ),
                const SizedBox(width: DesignTokens.spaceSM),
                Expanded(
                  child: Text(
                    'All subjects unlocked - pick any that interests you!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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

class SubjectData {
  final String key;
  final String displayName;
  final int completedProblems;
  final int totalProblems;
  final double masteryPercentage;
  final bool isLocked;
  final List<String> recentAchievements;
  
  const SubjectData({
    required this.key,
    required this.displayName,
    required this.completedProblems,
    required this.totalProblems,
    required this.masteryPercentage,
    this.isLocked = false,
    this.recentAchievements = const [],
  });
}