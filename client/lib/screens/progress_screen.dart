import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import '../state/game_state.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text('Your Progress', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: GameStateController.instance,
                builder: (context, _) => XPBar(xp: GameStateController.instance.xp, goal: 100),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: GameStateController.instance,
                builder: (context, _) {
                  final s = GameStateController.instance;
                  final correctRate = s.steps == 0 ? 0 : ((s.correct / s.steps) * 100).round();
                  return Row(children: [
                    Expanded(child: _StatCard(title: 'Sessions', value: '${s.sessions}')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(title: 'Correct Rate', value: '$correctRate%')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(title: 'Streak', value: '${s.streakDays}d')),
                  ]);
                },
              ),
              const SizedBox(height: 16),
              Glass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mastery Snapshot', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: GameStateController.instance,
                      builder: (context, _) {
                        final m = GameStateController.instance.masteryPercent;
                        final entries = m.isEmpty ? {'Algebraic Expressions': 0.0}.entries : m.entries;
                        return Column(
                          children: [
                            for (final e in entries) _Bar(title: e.key, pct: e.value),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String title;
  final double pct;
  const _Bar({required this.title, required this.pct});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title)),
              Text('${(pct * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(children: [
              Container(height: 8, color: Colors.white.withOpacity(0.1)),
              FractionallySizedBox(
                widthFactor: pct.clamp(0.02, 1.0),
                child: Container(height: 8, decoration: const BoxDecoration(gradient: AppGradients.primary)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
