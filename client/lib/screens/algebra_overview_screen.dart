import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import '../data/syllabus.dart';
import 'subtopic_screen.dart';

class AlgebraOverviewScreen extends StatelessWidget {
  const AlgebraOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get algebra subtopics from syllabus
    final algebraSubStrand = kP6Syllabus
        .expand((section) => section.subStrands)
        .firstWhere((subStrand) => subStrand.title.toLowerCase().contains('algebra'));
    
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
                'Number and Algebra',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Algebra',
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
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.blueAccent.withOpacity(0.2),
                        ),
                        child: const Icon(
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
                            const Text(
                              'Algebra',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Master variables, expressions, and equations with AI guidance',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _InfoChip(
                                  icon: Icons.psychology_rounded,
                                  label: 'AI Tutor',
                                  color: Colors.orangeAccent,
                                ),
                                const SizedBox(width: 12),
                                _InfoChip(
                                  icon: Icons.auto_awesome_rounded,
                                  label: '${algebraSubStrand.subTopics.length} Topics',
                                  color: Colors.purpleAccent,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Subtopics list
                Text(
                  'Choose a Topic to Start Learning',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: ListView.separated(
                    itemCount: algebraSubStrand.subTopics.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final subTopic = algebraSubStrand.subTopics[index];
                      return _SubTopicCard(
                        title: subTopic,
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => SubtopicScreen(
                              strand: 'Number and Algebra',
                              subStrand: 'Algebra',
                              subTopic: subTopic,
                            ),
                            transitionsBuilder: (_, a, __, child) => 
                              SlideTransition(
                                position: a.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
                                child: child,
                              ),
                          ),
                        ),
                      );
                    },
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

class _SubTopicCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SubTopicCard({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _getColorForTopic(title).withOpacity(0.2),
              ),
              child: Icon(
                _getIconForTopic(title),
                color: _getColorForTopic(title),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDescriptionForTopic(title),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTopic(String topic) {
    final t = topic.toLowerCase();
    if (t.contains('unknowns') || t.contains('notation')) return Icons.psychology_rounded;
    if (t.contains('simplify')) return Icons.compress_rounded;
    if (t.contains('substitution')) return Icons.find_replace_rounded;
    if (t.contains('equation')) return Icons.balance_rounded;
    return Icons.functions_rounded;
  }

  Color _getColorForTopic(String topic) {
    final t = topic.toLowerCase();
    if (t.contains('unknowns') || t.contains('notation')) return Colors.greenAccent;
    if (t.contains('simplify')) return Colors.blueAccent;
    if (t.contains('substitution')) return Colors.orangeAccent;
    if (t.contains('equation')) return Colors.redAccent;
    return Colors.purpleAccent;
  }

  String _getDescriptionForTopic(String topic) {
    final t = topic.toLowerCase();
    if (t.contains('unknowns') || t.contains('notation')) {
      return 'Learn to work with variables and form basic expressions';
    }
    if (t.contains('simplify')) {
      return 'Combine like terms and simplify algebraic expressions';
    }
    if (t.contains('substitution')) {
      return 'Evaluate expressions by replacing variables with numbers';
    }
    if (t.contains('equation')) {
      return 'Solve for unknown values in linear equations';
    }
    return 'Explore algebraic concepts with AI guidance';
  }
}