import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_client.dart';
import '../config.dart';
import 'tutor_screen.dart';
import '../ui/app_theme.dart';
import '../ui/design_tokens.dart';
import '../ui/components/subject_island_card.dart';
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
      name: 'Knowledge Seeker',
      description: 'Earned 500 XP',
      icon: Icons.auto_awesome_rounded,
      rarity: AchievementRarity.rare,
      isUnlocked: _currentXP >= 500,
      category: 'Progress',
      xpReward: 50,
    ));
    
    // Subject-specific achievements
    for (final subject in _subjects.values) {
      if (subject.completedProblems >= 10) {
        achievements.add(Achievement(
          id: '${subject.key}_explorer',
          name: '${subject.displayName} Explorer',
          description: 'Completed 10 ${subject.displayName} problems',
          icon: Icons.explore_rounded,
          rarity: AchievementRarity.common,
          isUnlocked: true,
          category: 'Subject Mastery',
          xpReward: 30,
        ));
      }
      
      if (subject.masteryPercentage >= 50) {
        achievements.add(Achievement(
          id: '${subject.key}_adept',
          name: '${subject.displayName} Adept',
          description: 'Achieved 50% mastery in ${subject.displayName}',
          icon: Icons.military_tech_rounded,
          rarity: AchievementRarity.rare,
          isUnlocked: true,
          category: 'Subject Mastery',
          xpReward: 75,
        ));
      }
      
      if (subject.masteryPercentage >= 90) {
        achievements.add(Achievement(
          id: '${subject.key}_master',
          name: '${subject.displayName} Master',
          description: 'Achieved 90% mastery in ${subject.displayName}',
          icon: Icons.emoji_events_rounded,
          rarity: AchievementRarity.epic,
          isUnlocked: true,
          category: 'Subject Mastery',
          xpReward: 150,
        ));
      }
    }
    
    // Streak achievements
    if (_streakDays >= 3) {
      achievements.add(Achievement(
        id: 'streak_3',
        name: 'Getting Started',
        description: 'Maintained a 3-day learning streak',
        icon: Icons.local_fire_department_rounded,
        rarity: AchievementRarity.common,
        isUnlocked: true,
        category: 'Consistency',
        xpReward: 40,
      ));
    }
    
    if (_streakDays >= 7) {
      achievements.add(Achievement(
        id: 'streak_7',
        name: 'Week Warrior',
        description: 'Maintained a 7-day learning streak',
        icon: Icons.local_fire_department_rounded,
        rarity: AchievementRarity.rare,
        isUnlocked: true,
        category: 'Consistency',
        xpReward: 100,
      ));
    }
    
    // Level achievements
    if (_currentLevel >= 5) {
      achievements.add(Achievement(
        id: 'level_5',
        name: 'Rising Scholar',
        description: 'Reached Level 5',
        icon: Icons.trending_up_rounded,
        rarity: AchievementRarity.rare,
        isUnlocked: true,
        category: 'Progress',
        xpReward: 60,
      ));
    }
    
    if (_currentLevel >= 10) {
      achievements.add(Achievement(
        id: 'level_10',
        name: 'Mathematical Mind',
        description: 'Reached Level 10',
        icon: Icons.psychology_rounded,
        rarity: AchievementRarity.epic,
        isUnlocked: true,
        category: 'Progress',
        xpReward: 125,
      ));
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
      
      // Extract gamification data
      final gamification = data['gamification'] as Map<String, dynamic>? ?? {};
      _currentXP = (gamification['xp'] as num?)?.toInt() ?? 0;
      _streakDays = (gamification['streak_days'] as num?)?.toInt() ?? 0;
      _currentLevel = (_currentXP / 100).floor() + 1; // Simple level calculation
      
      // Extract topics/subjects data
      final topics = data['topics'] as List<dynamic>? ?? [];
      final Map<String, SubjectData> subjectsData = {};
      
      // Get all available topics from catalog to know total counts
      final catalogTopics = await api.listTopics();
      final topicCounts = <String, int>{};
      for (final topic in catalogTopics) {
        final id = topic['id'] as String;
        final count = (topic['count'] as num?)?.toInt() ?? 0;
        topicCounts[id] = count;
      }
      
      // Create subjects from topics data
      for (final topic in topics) {
        final topicId = topic['id'] as String;
        final topicTitle = topic['title'] as String;
        final masteryPct = (topic['mastery_pct'] as num?)?.toDouble() ?? 0.0;
        final totalCount = topicCounts[topicId] ?? 0;
        final completedCount = (masteryPct * totalCount).round();
        
        final subjectKey = _getSubjectKey(topicId);
        subjectsData[subjectKey] = SubjectData(
          key: subjectKey,
          displayName: _getDisplayName(subjectKey),
          completedProblems: completedCount,
          totalProblems: totalCount,
          masteryPercentage: masteryPct * 100,
          isLocked: false, // Will be determined by smart logic below
          recentAchievements: [], // TODO: Extract from achievements data
        );
      }
      
      // Ensure all expected subjects are present with defaults if missing
      for (final subjectKey in _subjectDisplayNames.keys) {
        if (!subjectsData.containsKey(subjectKey)) {
          subjectsData[subjectKey] = SubjectData(
            key: subjectKey,
            displayName: _getDisplayName(subjectKey),
            completedProblems: 0,
            totalProblems: topicCounts[subjectKey] ?? 0,
            masteryPercentage: 0.0,
            isLocked: false, // Will be determined by smart logic below
            recentAchievements: [],
          );
        }
      }
      
      // Apply smart unlocking logic to all subjects
      for (final entry in subjectsData.entries.toList()) {
        final subjectKey = entry.key;
        final subjectData = entry.value;
        
        subjectsData[subjectKey] = SubjectData(
          key: subjectData.key,
          displayName: subjectData.displayName,
          completedProblems: subjectData.completedProblems,
          totalProblems: subjectData.totalProblems,
          masteryPercentage: subjectData.masteryPercentage,
          isLocked: !_isSubjectUnlocked(subjectKey, subjectsData),
          recentAchievements: subjectData.recentAchievements,
        );
      }
      
      setState(() {
        _feed = data;
        _subjects = subjectsData;
        _achievements = _generateAchievements();
        _feedError = null;
      });
      
      // Hydrate local gamification data
      try {
        final profile = await api.getProfile(learnerId: learnerId);
        final xp = (profile['xp'] as num?)?.toInt() ?? _currentXP;
        final mastery = Map<String, double>.from((profile['mastery_pct'] as Map?) ?? const {});
        final badges = ((profile['badges'] as List?)?.cast<String>()) ?? const <String>[];
        GameStateController.instance.hydrate(xp: xp, masteryPct: mastery, badges: badges);
        
        // Update XP if different from gamification data
        if (xp != _currentXP) {
          setState(() {
            _currentXP = xp;
            _currentLevel = (_currentXP / 100).floor() + 1;
            _achievements = _generateAchievements(); // Regenerate with updated XP
          });
        }
      } catch (_) {
        // Ignore hydration errors for MVP
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedError = 'Could not load recommendations. Please try again.';
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
          pageBuilder: (context, animation, secondaryAnimation) => LearningPathScreen(
            pathId: subjectKey,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      // Fallback to direct tutor screen if LearningPathScreen fails
      _startAdaptiveSession(subjectKey);
    }
  }
  
  /// Fallback method to start learning directly with adaptive session
  Future<void> _startAdaptiveSession(String subjectKey) async {
    setState(() => _busy = true);
    try {
      final api = ApiClient(kDefaultApiBase);
      final learnerId = ActiveLearner.instance.id ?? AuthService.getCurrentUserId() ?? 'guest';
      
      // For now, show a friendly message that this subject is coming soon
      // since the API doesn't have items loaded yet
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: DesignTokens.neutralSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
          ),
          title: Row(
            children: [
              Icon(
                Icons.rocket_launch_rounded,
                color: DesignTokens.getSubjectColor(subjectKey),
                size: 32,
              ),
              const SizedBox(width: DesignTokens.spaceSM),
              Expanded(
                child: Text(
                  '${_getDisplayName(subjectKey)} Adventure',
                  style: DesignTokens.sectionTitle.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceLG),
                decoration: BoxDecoration(
                  gradient: DesignTokens.getMagicalSubjectGradient(subjectKey),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceLG),
              Text(
                'Get ready for an amazing ${_getDisplayName(subjectKey)} learning adventure!',
                style: DesignTokens.bodyText.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceMD),
              Text(
                'We\'re preparing exciting problems and interactive lessons for you. Coming very soon!',
                style: DesignTokens.captionText.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.getSubjectColor(subjectKey),
              ),
              child: const Text('Can\'t wait!'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start ${_getDisplayName(subjectKey)} session. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  
  void _showLockedSubjectDialog(String subjectKey) {
    final subject = _subjects[subjectKey];
    if (subject == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.neutralSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock_rounded,
              color: DesignTokens.warningAura,
            ),
            const SizedBox(width: DesignTokens.spaceSM),
            Text(
              'Subject Locked',
              style: DesignTokens.sectionTitle.copyWith(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Complete more problems in other subjects to unlock ${subject.displayName}!',
          style: DesignTokens.bodyText.copyWith(color: Colors.white.withOpacity(0.9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyle(color: DesignTokens.primaryMagic),
            ),
          ),
        ],
      ),
    );
  }

  void _onAchievementTap(Achievement achievement) {
    if (!achievement.isUnlocked) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spaceLG),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.getSubjectColor('fractions'),
                DesignTokens.getSubjectColorLight('fractions'),
              ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                achievement.icon,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: DesignTokens.spaceMD),
              Text(
                achievement.name,
                style: DesignTokens.sectionTitle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceSM),
              Text(
                achievement.description,
                style: DesignTokens.bodyText.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceLG),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: DesignTokens.getSubjectColor('fractions'),
                ),
                child: const Text('Awesome!'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _loadingFeed
              ? _buildLoadingState()
              : _feedError != null
                  ? _buildErrorState()
                  : _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.white),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Glass(
        padding: const EdgeInsets.all(DesignTokens.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: DesignTokens.errorPulse,
            ),
            const SizedBox(height: DesignTokens.spaceMD),
            Text(
              'Oops! Something went wrong',
              style: DesignTokens.sectionTitle.copyWith(color: Colors.white),
            ),
            const SizedBox(height: DesignTokens.spaceSM),
            Text(
              _feedError!,
              style: DesignTokens.bodyText.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spaceLG),
            ElevatedButton(
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

  SliverAppBar _buildAnimatedHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: AnimatedBuilder(
        animation: _headerAnimation,
        child: FlexibleSpaceBar(
          title: Text(
            'Learning Journey',
            style: DesignTokens.heroTitle.copyWith(
              color: Colors.white,
              fontSize: 28,
            ),
          ),
          titlePadding: const EdgeInsets.only(
            left: DesignTokens.spaceMD,
            bottom: DesignTokens.spaceMD,
          ),
        ),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _headerAnimation.value) * -50),
            child: Opacity(
              opacity: _headerAnimation.value,
              child: child,
            ),
          );
        },
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Add profile/settings screen
          },
          icon: const Icon(
            Icons.account_circle_rounded,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildWelcomeSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _headerAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _headerAnimation.value) * 30),
            child: Opacity(
              opacity: _headerAnimation.value,
              child: Padding(
                padding: ResponsiveTokens.responsivePadding(context),
                child: Glass(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: DesignTokens.primaryMagic.withOpacity(0.2),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spaceMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, Scholar!',
                              style: DesignTokens.sectionTitle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Ready to continue your mathematical adventure?',
                              style: DesignTokens.bodyText.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildQuickStatsSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _headerAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _headerAnimation.value) * 40),
            child: Opacity(
              opacity: _headerAnimation.value,
              child: Padding(
                padding: ResponsiveTokens.responsivePadding(context),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.auto_awesome_rounded,
                        label: 'XP',
                        value: _currentXP.toString(),
                        color: DesignTokens.successGlow,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spaceSM),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Streak',
                        value: _streakDays > 0 ? '$_streakDays days' : 'Start today!',
                        color: DesignTokens.warningAura,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spaceSM),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.emoji_events_rounded,
                        label: 'Level',
                        value: _currentLevel.toString(),
                        color: DesignTokens.primaryMagic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Glass(
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: DesignTokens.spaceXS),
          Text(
            value,
            style: DesignTokens.subtitle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: DesignTokens.captionText.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSubjectGridSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _cardAnimation,
        builder: (context, child) {
          return Padding(
            padding: ResponsiveTokens.responsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mathematics Subjects',
                  style: DesignTokens.sectionTitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceMD),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveTokens.responsiveColumns(context),
                    childAspectRatio: 1.4, // Increased from 1.2 to make cards more compact
                    crossAxisSpacing: DesignTokens.spaceXS, // Reduced spacing
                    mainAxisSpacing: DesignTokens.spaceXS, // Reduced spacing
                  ),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final delay = index * 100;
                    final subject = _subjects.values.elementAt(index);
                    
                    return AnimatedBuilder(
                      animation: _cardAnimation,
                      builder: (context, child) {
                        final delayedAnimation = Tween<double>(
                          begin: 0.0,
                          end: 1.0,
                        ).animate(CurvedAnimation(
                          parent: _cardAnimation,
                          curve: Interval(
                            (delay / 1000).clamp(0.0, 0.8),
                            1.0,
                            curve: Curves.easeOutCubic,
                          ),
                        ));
                        
                        final animationValue = delayedAnimation.value.clamp(0.0, 1.0);
                        
                        return Transform.scale(
                          scale: animationValue,
                          child: Transform.translate(
                            offset: Offset(0, (1 - animationValue) * 50),
                            child: SubjectIslandCard(
                              subject: subject.key,
                              displayName: subject.displayName,
                              completedProblems: subject.completedProblems,
                              totalProblems: subject.totalProblems,
                              masteryPercentage: subject.masteryPercentage,
                              isLocked: subject.isLocked,
                              recentAchievements: subject.recentAchievements,
                              onTap: () => _navigateToSubject(subject.key),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildAchievementSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: ResponsiveTokens.responsivePadding(context),
        child: AchievementShowcase(
          achievements: _achievements,
          recentAchievements: _achievements.where((a) => a.isUnlocked).take(3).toList(),
          onAchievementTap: _onAchievementTap,
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildRecommendationsSection() {
    if (_feed == null || _feed!['items'] == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final items = _feed!['items'] as List;
    if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: ResponsiveTokens.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommended for You',
              style: DesignTokens.sectionTitle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMD),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.take(3).length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildRecommendationCard(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMD),
      child: Glass(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: DesignTokens.getSubjectColor(
              item['topic'] ?? 'mathematics',
            ).withOpacity(0.2),
            child: Icon(
              Icons.quiz_rounded,
              color: DesignTokens.getSubjectColor(item['topic'] ?? 'mathematics'),
            ),
          ),
          title: Text(
            item['title'] ?? 'Practice Problem',
            style: DesignTokens.subtitle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            item['complexity'] ?? 'Medium',
            style: DesignTokens.captionText.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white54,
            size: 16,
          ),
          onTap: () {
            // TODO: Start specific problem
          },
        ),
      ),
    );
  }
}

/// Data class for subject information
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