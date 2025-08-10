import 'dart:convert';
import 'package:flutter/material.dart';
import '../api_client.dart';
import '../config.dart';
import 'tutor_screen.dart';
import '../ui/app_theme.dart';
import '../state/game_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;
  Map<String, dynamic>? _feed;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final api = ApiClient(kDefaultApiBase);
    try {
      final data = await api.getHomeFeed(learnerId: 'demo');
      if (!mounted) return;
      setState(() => _feed = data);
    } catch (_) {
      // ignore and keep old UI if feed not available
    }
  }

  Future<void> _startSpecificItem(String? itemId) async {
    if (itemId == null) return _startAlgebraQuest();
    setState(() => _busy = true);
    final api = ApiClient(kDefaultApiBase);
    try {
      await api.ensureSampleItem();
      await _ensureAdditionalQuestions(api);
      final res = await api.startAdaptiveSession(learnerId: 'demo', itemId: itemId);
      if (!mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => TutorScreen(
            apiBase: kDefaultApiBase,
            sessionId: res['session_id'] as String,
            stepId: (res['step_id'] as String?) ?? 's1',
            prompt: (res['prompt'] as String?) ?? "Let's begin!",
          ),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueSession(String? sessionId) async {
    if (sessionId == null) return;
    setState(() => _busy = true);
    final api = ApiClient(kDefaultApiBase);
    try {
      final res = await api.getSession(sessionId: sessionId);
      if (!mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => TutorScreen(
            apiBase: kDefaultApiBase,
            sessionId: res['session_id'] as String,
            stepId: (res['step_id'] as String?) ?? 's1',
            prompt: (res['prompt'] as String?) ?? "Let's continue!",
          ),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not resume: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildRecommendations() {
    final feed = _feed;
    if (feed == null) {
      return ListView(
        children: const [
          _MiniCard(title: 'Bar Models Basics'),
          _MiniCard(title: 'Number Lines Warmup'),
          _MiniCard(title: 'Word Problems: Add/Subtract'),
        ],
      );
    }
    final forYou = (feed['for_you'] as List?) ?? const [];
    if (forYou.isEmpty) {
      return ListView(children: const [ _MiniCard(title: 'Explore topics to get recommendations') ]);
    }
    return ListView.builder(
      itemCount: forYou.length,
      itemBuilder: (context, i) {
        final it = forYou[i] as Map<String, dynamic>;
        final title = it['title'] as String? ?? 'Practice';
        final reason = it['reason'] as String? ?? '';
        return GestureDetector(
          onTap: _busy ? null : () => _startSpecificItem(it['item_id'] as String?),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Glass(
              radius: 16,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(reason, style: const TextStyle(color: Colors.white70)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _startAlgebraQuest() async {
    setState(() => _busy = true);
    final api = ApiClient(kDefaultApiBase);
    try {
      // Ensure all algebra items exist (this will ingest multiple questions)
      await api.ensureSampleItem();
      await _ensureAdditionalQuestions(api);
      
      // Start adaptive session (will automatically pick the right question based on progress)
      final res = await api.startAdaptiveSession(learnerId: 'demo');
      if (!mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => TutorScreen(
            apiBase: kDefaultApiBase,
            sessionId: res['session_id'] as String,
            stepId: (res['step_id'] as String?) ?? 's1',
            prompt: (res['prompt'] as String?) ?? "Let's begin our algebra journey!",
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

  Future<void> _ensureAdditionalQuestions(ApiClient api) async {
    try {
      // Check if second question exists
      await api.getItem(itemId: 'ALG-S1-E2');
    } catch (_) {
      // Ingest additional questions if missing
      const question2Json = '''
{
  "topic": "Algebra",
  "version": "enhanced-v1",
  "items": [
    {
      "id": "ALG-S1-E2",
      "topic": "Algebra", 
      "title": "Multiplying an Unknown",
      "learn_step": 1,
      "complexity": "Easy",
      "difficulty": 0.3,
      "skill": "Algebraic Expressions",
      "subskills": ["use-variable", "form-multiplication-expression"],
      "estimated_time_seconds": 30,
      "problem_text": "A box contains 'n' pencils. How many pencils are there in 5 such boxes? Write an expression in terms of 'n'.",
      "assets": {"manipulatives": [], "image_url": null, "svg_code": null},
      "student_view": {
        "socratic": true,
        "steps": [
          {
            "id": "s1",
            "prompt": "If one box has n pencils, how many pencils are in 5 boxes total?",
            "hints": [
              {"level": 1, "text": "Think about finding the total for multiple groups."},
              {"level": 2, "text": "The operation needed is multiplication."},
              {"level": 3, "text": "Write it as 5n (5 times n)."}
            ]
          }
        ],
        "reflect_prompts": ["Why is it multiplication and not addition?"],
        "micro_drills": []
      },
      "teacher_view": {
        "solutions_teacher": ["5n"],
        "common_pitfalls": [{"text": "n+5 instead of 5n", "tag": "addition-for-multiply"}]
      },
      "telemetry": {"scoring": {"xp": 10, "bonus_no_hints": 2}, "prereqs": [], "next_items": []},
      "evaluation": {
        "rules": {
          "regex": [{"equivalent_to": "5n"}],
          "algebraic_equivalence": true,
          "llm_fallback": true
        },
        "notes": "Regex → CAS → LLM adjudication"
      }
    }
  ]
}''';
      await api.ingestJson(jsonData: question2Json);

      const question3Json = '''
{
  "topic": "Algebra",
  "version": "enhanced-v1", 
  "items": [
    {
      "id": "ALG-S1-M1",
      "topic": "Algebra",
      "title": "Division as a Fraction", 
      "learn_step": 1,
      "complexity": "Medium",
      "difficulty": 0.5,
      "skill": "Algebraic Expressions",
      "subskills": ["use-variable", "form-division-expression"],
      "estimated_time_seconds": 45,
      "problem_text": "A rope of 'k' metres long is cut into 8 equal pieces. Write an expression for the length of each piece of rope.",
      "assets": {"manipulatives": [], "image_url": null, "svg_code": null},
      "student_view": {
        "socratic": true,
        "steps": [
          {
            "id": "s1",
            "prompt": "If a rope of k metres is cut into 8 equal pieces, what is the length of each piece?", 
            "hints": [
              {"level": 1, "text": "The total length is k metres."},
              {"level": 2, "text": "Cut into equal pieces means division."},
              {"level": 3, "text": "Write it as k/8 (k divided by 8)."}
            ]
          }
        ],
        "reflect_prompts": ["Why is it division and not subtraction?"],
        "micro_drills": []
      },
      "teacher_view": {
        "solutions_teacher": ["k/8"],
        "common_pitfalls": [{"text": "k-8 instead of k/8", "tag": "subtraction-for-division"}]
      },
      "telemetry": {"scoring": {"xp": 15, "bonus_no_hints": 3}, "prereqs": [], "next_items": []},
      "evaluation": {
        "rules": {
          "regex": [{"equivalent_to": "k/8"}],
          "algebraic_equivalence": true,
          "llm_fallback": true
        },
        "notes": "Regex → CAS → LLM adjudication"
      }
    }
  ]
}''';
      await api.ingestJson(jsonData: question3Json);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back, Learner', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text('Let\'s learn something awesome ✨', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: GameStateController.instance,
                    builder: (context, _) => StreakPill(days: GameStateController.instance.streakDays),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: GameStateController.instance,
                builder: (context, _) => XPBar(xp: GameStateController.instance.xp, goal: 100),
              ),
              const SizedBox(height: 18),
              Text('Daily Quest', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (_feed == null)
                _QuestCard(
                  title: 'Algebra Starter',
                  subtitle: 'P6 • Expressions • 1–2 mins',
                  color: Colors.indigoAccent,
                  onTap: _busy ? null : _startAlgebraQuest,
                )
              else ...[
                if (_feed!["continue"] != null)
                  _QuestCard(
                    title: _feed!["continue"]["title"] ?? 'Continue',
                    subtitle: 'Resume • ${(_feed!["continue"]["est_seconds"] ?? 60)}s',
                    color: Colors.tealAccent,
                    onTap: _busy
                        ? null
                        : () => _continueSession(_feed!["continue"]["session_id"] as String?),
                  ),
                if ((_feed!["daily_quest"] as List).isNotEmpty)
                  _QuestCard(
                    title: (_feed!["daily_quest"][0]["title"] as String?) ?? 'Daily Quest',
                    subtitle: '${_feed!["daily_quest"][0]["topic"]} • ${(_feed!["daily_quest"][0]["est_seconds"] ?? 60)}s',
                    color: Colors.indigoAccent,
                    onTap: _busy
                        ? null
                        : () => _startSpecificItem(_feed!["daily_quest"][0]["id"] as String?),
                  ),
              ],
              const SizedBox(height: 18),
              Text('Recommended', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
              const SizedBox(height: 8),
              Expanded(
                child: _buildRecommendations(),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Glass(
        radius: 24,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Row(children: const [Icon(Icons.play_arrow_rounded), SizedBox(width: 6), Text('Start')]),
                  ],
                ),
              ),
              Container(
                width: 8,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(colors: [color, Colors.white.withOpacity(0.7)]),
                ),
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white70),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
