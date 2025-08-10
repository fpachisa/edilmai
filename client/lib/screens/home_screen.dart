import 'package:flutter/material.dart';
import '../api_client.dart';
import '../config.dart';
import 'tutor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;

  Future<void> _startAlgebraQuest() async {
    setState(() => _busy = true);
    final api = ApiClient(kDefaultApiBase);
    try {
      // Ensure sample item exists (ingest silently if needed)
      await api.ensureSampleItem();
      final res = await api.startSession(learnerId: 'demo', itemId: 'ALG-S1-E1');
      if (!mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => TutorScreen(
            apiBase: kDefaultApiBase,
            sessionId: res['session_id'] as String,
            stepId: (res['step_id'] as String?) ?? 's1',
            prompt: (res['prompt'] as String?) ?? "Let's begin.",
          ),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start quest: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1024), Color(0xFF1A1E3A)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quests', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
              const SizedBox(height: 12),
              _QuestCard(
                title: 'Algebra Starter',
                subtitle: 'P6 • Expressions • 1–2 mins',
                color: Colors.indigoAccent,
                onTap: _busy ? null : _startAlgebraQuest,
              ),
              const SizedBox(height: 16),
              Text('Recommended', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: const [
                    _MiniCard(title: 'Bar Models Basics'),
                    _MiniCard(title: 'Number Lines Warmup'),
                    _MiniCard(title: 'Word Problems: Add/Subtract'),
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

class _QuestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  const _QuestCard({required this.title, required this.subtitle, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 8))],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 12),
                  Row(children: const [Icon(Icons.play_arrow_rounded, color: Colors.white), SizedBox(width: 6), Text('Start', style: TextStyle(color: Colors.white))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  const _MiniCard({required this.title});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white70),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

