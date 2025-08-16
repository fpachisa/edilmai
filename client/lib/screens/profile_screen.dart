import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import '../state/game_state.dart';
import '../auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Row(children: [
                _GradientAvatar(size: 72),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    AuthService.currentUser?.displayName ?? AuthService.currentUser?.email ?? 'Learner',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text('Keep the streak going!', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                ]),
              ]),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: GameStateController.instance,
                builder: (context, _) => XPBar(xp: GameStateController.instance.xp, goal: 100),
              ),
              const SizedBox(height: 16),
              Text('Badges', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: GameStateController.instance,
                builder: (context, _) {
                  final badges = GameStateController.instance.badges;
                  final children = badges.isEmpty
                      ? const [Padding(padding: EdgeInsets.all(8.0), child: Text('No badges yet. Keep going!'))]
                      : badges.map((b) => _badgeFor(b)).toList();
                  return Glass(
                    child: Wrap(spacing: 12, runSpacing: 12, children: children),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  final double size;
  const _GradientAvatar({required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.primary,
      ),
      child: const Center(child: Icon(Icons.person_rounded, size: 40, color: Colors.white)),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Badge({required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      radius: 16,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(label),
      ]),
    );
  }
}

Widget _badgeFor(String label) {
  switch (label) {
    case 'First Steps':
      return const _Badge(label: 'First Steps', icon: Icons.rocket_launch_rounded, color: Colors.cyanAccent);
    case 'No Hints':
      return const _Badge(label: 'No Hints', icon: Icons.lightbulb_rounded, color: Colors.amberAccent);
    case 'Streak 3':
      return const _Badge(label: 'Streak 3', icon: Icons.local_fire_department_rounded, color: Colors.orangeAccent);
    case 'Algebra Start':
      return const _Badge(label: 'Algebra Start', icon: Icons.calculate_rounded, color: Colors.purpleAccent);
    default:
      return _Badge(label: label, icon: Icons.emoji_events_rounded, color: Colors.tealAccent);
  }
}
