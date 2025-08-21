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
  late AnimationController _ctaPulseController;
  late AnimationController _shimmerController;
  
  late Animation<double> _heroFadeIn;
  late Animation<Offset> _heroSlideIn;
  late Animation<double> _featuresStagger;
  late Animation<double> _statsCountUp;
  late Animation<double> _ctaPulse;
  late Animation<double> _shimmer;

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
    _ctaPulseController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2400),
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
    // CTA pulse
    _ctaPulse = Tween<double>(begin: 0.96, end: 1.08).animate(
      CurvedAnimation(parent: _ctaPulseController, curve: Curves.easeInOut),
    );
    _ctaPulseController.repeat(reverse: true);
    // Shimmer sweep across the hero
    _shimmer = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _featuresController.dispose();
    _statsController.dispose();
    _ctaPulseController.dispose();
    _shimmerController.dispose();
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
                const SizedBox(height: 24),
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

  List<_FeatureData> _featuresData() => [
        _FeatureData(
          icon: Icons.psychology_alt_rounded,
          title: 'AI-Powered Socratic Method',
          description:
              'Learn through guided questioning that helps you discover answers naturally',
          color: const Color(0xFF6366F1),
        ),
        _FeatureData(
          icon: Icons.trending_up_rounded,
          title: 'Adaptive Learning Path',
          description:
              'Personalized progression that adjusts to your learning pace and style',
          color: const Color(0xFF059669),
        ),
        _FeatureData(
          icon: Icons.psychology_rounded,
          title: 'Misconception Detection',
          description:
              'Smart system identifies and addresses your specific learning gaps',
          color: const Color(0xFFF59E0B),
        ),
        _FeatureData(
          icon: Icons.auto_awesome_rounded,
          title: 'Instant Feedback',
          description:
              'Get immediate, contextual guidance without revealing the answer',
          color: const Color(0xFFEC4899),
        ),
      ];

  Widget _buildHeroAndFeaturesRow() {
    final features = _featuresData();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact hero
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.primary,
                      ),
                      child: const Icon(Icons.psychology_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'PSLE AI Tutor',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Master PSLE Maths with AI Tutoring',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Personalized questions, instant feedback, and a learning path that adapts to you.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _getStarted,
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: const Text('Start Learning Now'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Features grid visible above the fold
          Expanded(
            flex: 7,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) => _FeatureCard(
                feature: features[index],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                  const SizedBox(height: 20),
                  
                  // AI Brain Icon with Glow Effect
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.primary,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
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
                  )),
                  
                  const SizedBox(height: 20),
                  
                  // Main Headline with brand gradient background (full bleed within page padding)
                  Stack(
                    children: [
                      // Base gradient hero
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.zero,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Mastering PSLE Maths\nwith AI Tutoring',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            // Subtitle
                            Text(
                              'Experience the power of Socratic questioning.\nPersonalized learning that adapts to you.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 15,
                                    height: 1.4,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Shimmer overlay
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, _) {
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  final width = constraints.maxWidth;
                                  final height = constraints.maxHeight;
                                  final bandWidth = width * 0.28;
                                  final dx = (_shimmer.value) * (width + bandWidth) - bandWidth;
                                  return Transform.translate(
                                    offset: Offset(dx, 0),
                                    child: Container(
                                      width: bandWidth,
                                      height: height,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0.0),
                                            Colors.white.withOpacity(0.24),
                                            Colors.white.withOpacity(0.0),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Primary CTA Button with subtle pulse animation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: AnimatedBuilder(
                    animation: _ctaPulseController,
                    builder: (context, _) {
                      final t = (_ctaPulse.value - 0.98) / (1.03 - 0.98);
                      return ScaleTransition(
                        scale: _ctaPulse,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: AppGradients.primary,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.25 + 0.15 * t),
                                blurRadius: 16 + 8 * t,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _getStarted,
                              borderRadius: BorderRadius.circular(28),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.rocket_launch_rounded, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Start Learning Now',
                                      style: TextStyle(
                                        fontSize: 15,
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
                      );
                    },
                  )),
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
        color: const Color(0xFF6366F1),
      ),
      _FeatureData(
        icon: Icons.trending_up_rounded,
        title: 'Adaptive Learning Path',
        description: 'Personalized progression that adjusts to your learning pace and style',
        color: const Color(0xFF059669),
      ),
      _FeatureData(
        icon: Icons.psychology_rounded,
        title: 'Misconception Detection',
        description: 'Smart system identifies and addresses your specific learning gaps',
        color: const Color(0xFFF59E0B),
      ),
      _FeatureData(
        icon: Icons.auto_awesome_rounded,
        title: 'Instant Feedback',
        description: 'Get immediate, contextual guidance without revealing the answer',
        color: const Color(0xFFEC4899),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Choose Our AI Tutor?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cutting-edge technology meets proven pedagogical methods',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _featuresController,
            builder: (context, child) {
              return _buildResponsiveFeatureGrid(features);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveFeatureGrid(List<_FeatureData> features) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;
        double aspect;

        final w = constraints.maxWidth;
        if (w >= 1400) {
          columns = 4; // Wide desktop
          aspect = 1.6;
        } else if (w >= 992) {
          columns = 3; // Laptop
          aspect = 1.5;
        } else if (w >= 720) {
          columns = 2; // Tablet
          aspect = 1.2; // compact
        } else {
          columns = 1; // Mobile
          aspect = 1.0; // safe on small devices
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: aspect,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            final delay = index * 0.1;
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
                child: _FeatureCard(feature: feature),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Proven Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
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
                        color: const Color(0xFF059669),
                      ),
                    ),
                    Expanded(
                      child: _StatCard(
                        value: (_statsCountUp.value * 10).round(),
                        label: 'Misconceptions Detected',
                        suffix: '+',
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    Expanded(
                      child: _StatCard(
                        value: (_statsCountUp.value * 50).round(),
                        label: 'Questions Available',
                        suffix: '+',
                        color: const Color(0xFF6366F1),
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
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.school_rounded,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ready to Excel in PSLE Maths?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Join thousands of students who are already improving their math skills with our AI tutor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                          Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1)),
                          SizedBox(width: 8),
                          Text(
                            'Begin Your Journey',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1),
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
    Color lighten(Color c, double amount) {
      final hsl = HSLColor.fromColor(c);
      final l = (hsl.lightness + amount).clamp(0.0, 0.82); // cap lightness for contrast
      return hsl.withLightness(l).toColor();
    }

    final base = feature.color;
    final light = lighten(base, 0.24);
    final glow = lighten(base, 0.38);
    final useDarkText = base.computeLuminance() > 0.6;
    final textColor = useDarkText ? const Color(0xFF0B1220) : Colors.white;
    final subTextColor = useDarkText ? const Color(0xFF1F2937) : Colors.white.withOpacity(0.96);

    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 480 ? 14 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, light, glow],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: base.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(useDarkText ? 0.12 : 0.18), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: MediaQuery.of(context).size.width < 480 ? 48 : 56,
            height: MediaQuery.of(context).size.width < 480 ? 48 : 56,
            decoration: BoxDecoration(
              color: (useDarkText ? Colors.black : Colors.white).withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (useDarkText ? Colors.black : Colors.white).withOpacity(0.22), width: 1),
            ),
            child: Icon(
              feature.icon,
              size: MediaQuery.of(context).size.width < 480 ? 22 : 26,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            feature.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 480 ? 15 : 17,
              fontWeight: FontWeight.w700,
              color: textColor,
              shadows: [
                if (!useDarkText)
                  Shadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feature.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 480 ? 13 : 14,
              color: subTextColor,
              height: 1.35,
              fontWeight: FontWeight.w600,
              shadows: [
                if (!useDarkText)
                  Shadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              suffix,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
