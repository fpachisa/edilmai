import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _featuresController;
  late AnimationController _statsController;
  
  late Animation<double> _heroFadeIn;
  late Animation<Offset> _heroSlideIn;
  late Animation<double> _featuresStagger;
  late Animation<double> _statsCountUp;

  @override
  void initState() {
    super.initState();
    
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _featuresController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _heroFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
    );
    
    _heroSlideIn = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOut));
    
    _featuresStagger = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _featuresController, curve: Curves.easeOut),
    );
    
    _statsCountUp = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOut),
    );

    // Start animations
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _featuresController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _statsController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _featuresController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  void _getStarted() {
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroSection(),
                const SizedBox(height: 40),
                _buildFeaturesSection(),
                const SizedBox(height: 40),
                _buildStatsSection(),
                const SizedBox(height: 40),
                _buildCTASection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: AnimatedBuilder(
        animation: _heroController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _heroFadeIn,
            child: SlideTransition(
              position: _heroSlideIn,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // AI Brain Icon with Glow Effect
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.primary,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Main Headline
                  Text(
                    'Master PSLE Maths\nwith AI Tutoring',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      fontSize: 36,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  Text(
                    'Experience the power of Socratic questioning.\nPersonalized learning that adapts to you.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      fontSize: 18,
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Primary CTA Button
                  Glass(
                    radius: 28,
                    padding: EdgeInsets.zero,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: AppGradients.primary,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _getStarted,
                          borderRadius: BorderRadius.circular(28),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.rocket_launch_rounded, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Start Learning Now',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      _FeatureData(
        icon: Icons.psychology_alt_rounded,
        title: 'AI-Powered Socratic Method',
        description: 'Learn through guided questioning that helps you discover answers naturally',
        color: Colors.purpleAccent,
      ),
      _FeatureData(
        icon: Icons.trending_up_rounded,
        title: 'Adaptive Learning Path',
        description: 'Personalized progression that adjusts to your learning pace and style',
        color: Colors.cyanAccent,
      ),
      _FeatureData(
        icon: Icons.psychology_rounded,
        title: 'Misconception Detection',
        description: 'Smart system identifies and addresses your specific learning gaps',
        color: Colors.greenAccent,
      ),
      _FeatureData(
        icon: Icons.auto_awesome_rounded,
        title: 'Instant Feedback',
        description: 'Get immediate, contextual guidance without revealing the answer',
        color: Colors.orangeAccent,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Choose Our AI Tutor?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cutting-edge technology meets proven pedagogical methods',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _featuresController,
            builder: (context, child) {
              return Column(
                children: features.asMap().entries.map((entry) {
                  final index = entry.key;
                  final feature = entry.value;
                  final delay = index * 0.2;
                  final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _featuresController,
                      curve: Interval(delay, 1.0, curve: Curves.easeOut),
                    ),
                  );
                  
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _FeatureCard(feature: feature),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Glass(
        radius: 24,
        child: Column(
          children: [
            Text(
              'Proven Results',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _statsController,
              builder: (context, child) {
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: (_statsCountUp.value * 95).round(),
                        label: 'Success Rate',
                        suffix: '%',
                        color: Colors.greenAccent,
                      ),
                    ),
                    Expanded(
                      child: _StatCard(
                        value: (_statsCountUp.value * 10).round(),
                        label: 'Misconceptions Detected',
                        suffix: '+',
                        color: Colors.orangeAccent,
                      ),
                    ),
                    Expanded(
                      child: _StatCard(
                        value: (_statsCountUp.value * 50).round(),
                        label: 'Questions Available',
                        suffix: '+',
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTASection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Glass(
        radius: 28,
        child: Column(
          children: [
            const Icon(
              Icons.school_rounded,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'Ready to Excel in PSLE Maths?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join thousands of students who are already improving their math skills with our AI tutor',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: AppGradients.primary,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _getStarted,
                    borderRadius: BorderRadius.circular(28),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Begin Your Journey',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: feature.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              feature.icon,
              size: 28,
              color: feature.color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final String suffix;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.suffix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              suffix,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}