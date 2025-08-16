import 'dart:convert';
import 'package:flutter/material.dart';
import '../api_client.dart';
import '../config.dart';
import 'tutor_screen.dart';
import '../ui/app_theme.dart';
import '../state/game_state.dart';
import '../ui/shimmer.dart';
import '../ui/mastery_ring.dart';
import '../ui/level_ring.dart';
import '../data/syllabus.dart';
import '../auth_service.dart';
import '../state/active_learner.dart';
import 'learning_path_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;
  Map<String, dynamic>? _feed;
  bool _loadingFeed = true;
  String? _feedError;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final api = ApiClient(kDefaultApiBase);
    // Resolve learner ID from active learner (preferred) then fallback
    final learnerId = ActiveLearner.instance.id ?? AuthService.getCurrentUserId() ?? 'guest';
    setState(() {
      _loadingFeed = true;
      _feedError = null;
    });
    try {
      final data = await api.getHomeFeed(learnerId: learnerId);
      if (!mounted) return;
      setState(() {
        _feed = data;
        _feedError = null;
      });
      // Hydrate local gamification/mastery from server profile when available
      try {
        final profile = await api.getProfile(learnerId: learnerId);
        final xp = (profile['xp'] as num?)?.toInt();
        // Expecting mastery as server-side later; fallback to existing
        final mastery = Map<String, double>.from((profile['mastery_pct'] as Map?) ?? const {});
        final badges = ((profile['badges'] as List?)?.cast<String>()) ?? const <String>[];
        GameStateController.instance.hydrate(xp: xp, masteryPct: mastery, badges: badges);
      } catch (_) {
        // ignore hydration errors for MVP
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

  Future<void> _startSpecificItem(String? itemId) async {
    if (itemId == null) return _startAlgebraQuest();
    setState(() => _busy = true);
    final api = ApiClient(kDefaultApiBase);
    final learnerId = ActiveLearner.instance.id ?? AuthService.getCurrentUserId() ?? 'guest';
    try {
      await api.ensureSampleItem();
      await _ensureAdditionalQuestions(api);
      final res = await api.startAdaptiveSession(learnerId: learnerId, itemId: itemId);
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
    if (_loadingFeed) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, i) => const _MiniCardSkeleton(),
      );
    }
    final feed = _feed;
    if (feed == null) {
      // No feed available (e.g., API down). Show static suggestions with retry.
      return ListView(
        children: [
          if (_feedError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ErrorBanner(message: _feedError!, onRetry: _busy ? null : _loadFeed),
            ),
          const _MiniCard(title: 'Bar Models Basics'),
          const _MiniCard(title: 'Number Lines Warmup'),
          const _MiniCard(title: 'Word Problems: Add/Subtract'),
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
    final learnerId = ActiveLearner.instance.id ?? AuthService.getCurrentUserId() ?? 'guest';
    try {
      // Ensure all algebra items exist (this will ingest multiple questions)
      await api.ensureSampleItem();
      await _ensureAdditionalQuestions(api);
      
      // Start adaptive session (will automatically pick the right question based on progress)
      final res = await api.startAdaptiveSession(learnerId: learnerId);
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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Learning as: ${ActiveLearner.instance.name}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text('Let\'s learn something awesome ✨',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: GameStateController.instance,
                          builder: (context, _) => LevelRing(xp: GameStateController.instance.xp),
                        ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: GameStateController.instance,
                          builder: (context, _) => StreakPill(days: GameStateController.instance.streakDays),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              // Topics mastery rings row (hidden until progress exists)
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: GameStateController.instance,
                  builder: (context, _) {
                    final m = GameStateController.instance.masteryPercent;
                    final entries = m.entries.toList()
                      ..sort((a, b) => (b.value).compareTo(a.value));
                    final filtered = entries.where((e) => (e.value) > 0).toList();
                    if (filtered.isEmpty) return const SizedBox.shrink();
                    final items = filtered.map((e) => _TopicRingData(e.key, e.value)).toList();
                    final count = items.length > 8 ? 8 : items.length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Topics', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 128,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, i) {
                              final t = items[i];
                              return MasteryRing(
                                label: t.label,
                                progress: t.pct,
                                onTap: _busy
                                    ? null
                                    : () {
                                        if (t.label.toLowerCase().contains('algebra')) {
                                          _startSpecificItem('ALG-S1-E1');
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Explore for this topic is coming soon')));
                                        }
                                      },
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(width: 14),
                            itemCount: count,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ),
              // Browse Syllabus — richer UI with a carousel per strand
              SliverToBoxAdapter(
                child: _SyllabusCarousel(onSelect: (title) {
                  if (title.toLowerCase().contains('algebra')) {
                    _startSpecificItem('ALG-S1-E1');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('“$title” coming soon')),
                    );
                  }
                }),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverToBoxAdapter(child: _DailyQuestSection(loading: _loadingFeed, feed: _feed, error: _feedError, busy: _busy, onStart: _startAlgebraQuest, onResume: _continueSession, onRetry: _loadFeed)),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverToBoxAdapter(
                child: Text('Recommended', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              // Recommendations as a sliver list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tiles = _recommendationTiles(context);
                    if (index >= tiles.length) return null;
                    return tiles[index];
                  },
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

class _DailyQuestSection extends StatelessWidget {
  final bool loading;
  final Map<String, dynamic>? feed;
  final String? error;
  final bool busy;
  final Future<void> Function() onStart;
  final Future<void> Function(String? sessionId) onResume;
  final Future<void> Function() onRetry;
  const _DailyQuestSection({required this.loading, required this.feed, required this.error, required this.busy, required this.onStart, required this.onResume, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (loading) return const _QuestCardSkeleton();
    if (feed == null) {
      return Column(children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ErrorBanner(message: error!, onRetry: busy ? null : onRetry),
          ),
        _DailyQuestHero(title: 'Daily Quest', subtitle: 'P6 • Algebra • 1–2 mins', onTap: busy ? null : onStart),
      ]);
    }
    final cont = feed!["continue"] as Map<String, dynamic>?;
    final dqList = (feed!["daily_quest"] as List?) ?? const [];
    final dq = dqList.isNotEmpty ? dqList[0] as Map<String, dynamic> : null;
    return Column(children: [
      if (cont != null)
        _DailyQuestHero(
          title: cont["title"] as String? ?? 'Continue',
          subtitle: 'Resume • ${(cont["est_seconds"] ?? 60)}s',
          color: Colors.tealAccent,
          onTap: busy ? null : () => onResume(cont["session_id"] as String?),
          resume: true,
        ),
      if (dq != null)
        _DailyQuestHero(
          title: dq["title"] as String? ?? 'Daily Quest',
          subtitle: '${dq["topic"]} • ${(dq["est_seconds"] ?? 60)}s',
          color: Colors.indigoAccent,
          onTap: busy ? null : onStart,
        ),
    ]);
  }
}

class _DailyQuestHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color color;
  final bool resume;
  const _DailyQuestHero({required this.title, required this.subtitle, required this.onTap, this.color = Colors.indigoAccent, this.resume = false});

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(colors: [color, Colors.white.withOpacity(0.7)]);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.all(0),
        child: Container(
          height: 160,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
          child: Row(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(resume ? 'Resume' : 'Today\'s Quest', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(subtitle, style: const TextStyle(color: Colors.white70)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: const [Icon(Icons.play_arrow_rounded), SizedBox(width: 6), Text('Start')]),
                  ],
                ),
              ),
            ),
            Container(
              width: 8,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: gradient),
            ),
          ]),
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

class _MiniCardSkeleton extends StatelessWidget {
  const _MiniCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Shimmer(
        child: Glass(
          radius: 16,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 160, decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(6))),
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

class _AchievementsAndGoal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: GameStateController.instance,
          builder: (context, _) {
            final badges = GameStateController.instance.badges.toList();
            final latest = badges.isNotEmpty ? badges.last : null;
            return Row(children: [
              Expanded(
                child: Glass(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.amberAccent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(latest != null ? 'Latest badge: $latest' : 'Earn badges as you learn!')),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Glass(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    const Icon(Icons.flag_rounded, color: Colors.lightBlueAccent),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Weekly goal: solve 3 items')),
                  ]),
                ),
              ),
            ]);
          },
        ),
      ],
    );
  }
}

class _QuestCardSkeleton extends StatelessWidget {
  const _QuestCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Glass(
        radius: 24,
        child: SizedBox(
          height: 150,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 20, width: 180, decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 10),
                      Container(height: 14, width: 220, decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 16),
                      Row(children: [
                        Container(width: 18, height: 18, decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 8),
                        Container(height: 14, width: 60, decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(6))),
                      ]),
                    ],
                  ),
                ),
              ),
              Container(
                width: 8,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorBanner({required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.orangeAccent),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          const SizedBox(width: 10),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _TopicRingData {
  final String label;
  final double pct;
  const _TopicRingData(this.label, this.pct);
}

List<Widget> _recommendationTiles(BuildContext context) {
  final state = context.findAncestorStateOfType<_HomeScreenState>();
  if (state == null) return const [];
  if (state._loadingFeed) {
    return List.generate(5, (_) => const _MiniCardSkeleton());
  }
  if (state._feed == null) {
    return [
      if (state._feedError != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ErrorBanner(message: state._feedError!, onRetry: state._busy ? null : state._loadFeed),
        ),
      const _MiniCard(title: 'Bar Models Basics'),
      const _MiniCard(title: 'Number Lines Warmup'),
      const _MiniCard(title: 'Word Problems: Add/Subtract'),
    ];
  }
  final forYou = (state._feed!['for_you'] as List?) ?? const [];
  if (forYou.isEmpty) {
    return const [ _MiniCard(title: 'Explore topics to get recommendations') ];
  }
  return List.generate(forYou.length, (i) {
    final it = forYou[i] as Map<String, dynamic>;
    final title = it['title'] as String? ?? 'Practice';
    final reason = it['reason'] as String? ?? '';
    return GestureDetector(
      onTap: state._busy ? null : () => state._startSpecificItem(it['item_id'] as String?),
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
                  const SizedBox(height: 6),
                  if (reason.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.lightbulb_rounded, size: 16, color: Colors.white),
                        label: Text(reason, style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  });
}

class _SubStrandCard extends StatelessWidget {
  final String title;
  final List<String> topics;
  final void Function(String topic) onTapTopic;
  const _SubStrandCard({required this.title, required this.topics, required this.onTapTopic});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.book_rounded, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: topics
                      .map((t) => ChoiceChip(
                            label: Text(t),
                            selected: false,
                            onSelected: (_) => onTapTopic(t),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyllabusCarousel extends StatefulWidget {
  final void Function(String subStrandOrTopic) onSelect;
  const _SyllabusCarousel({required this.onSelect});

  @override
  State<_SyllabusCarousel> createState() => _SyllabusCarouselState();
}

class _SyllabusCarouselState extends State<_SyllabusCarousel> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Browse Syllabus', 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                )),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded, size: 16, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text('${_getAllSubStrands().length} topics', 
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildModernGrid(context),
      ],
    );
  }

  List<_TopicCardData> _getAllSubStrands() {
    final List<_TopicCardData> allTopics = [];
    for (final section in kP6Syllabus) {
      for (final ss in section.subStrands) {
        allTopics.add(_TopicCardData(
          title: ss.title,
          strand: section.strand,
          topics: ss.subTopics,
          icon: _iconForSubStrand(ss.title),
          strandIcon: _iconForStrand(section.strand),
          difficulty: _getDifficultyForSubStrand(ss.title),
        ));
      }
    }
    return allTopics;
  }

  Widget _buildModernGrid(BuildContext context) {
    final topics = _getAllSubStrands();
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Better responsive breakpoints
    int crossAxisCount;
    double childAspectRatio;
    
    if (screenWidth > 1200) {
      crossAxisCount = 4;
      childAspectRatio = 1.1;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
      childAspectRatio = 1.0;
    } else if (screenWidth > 600) {
      crossAxisCount = 2;
      childAspectRatio = 1.1;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 1.3;
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        return _ModernTopicCard(
          data: topic,
          onTap: () => _navigateToSubtopic(topic),
        );
      },
    );
  }

  String _getDifficultyForSubStrand(String title) {
    final t = title.toLowerCase();
    if (t.contains('basic') || t.contains('introduction')) return 'Beginner';
    if (t.contains('advanced') || t.contains('complex')) return 'Advanced';
    return 'Intermediate';
  }

  void _navigateToSubtopic(_TopicCardData topic) {
    // Map topic titles to path IDs
    String? pathId;
    if (topic.title.toLowerCase().contains('algebra')) {
      pathId = 'algebra';
    } else if (topic.title.toLowerCase().contains('fractions')) {
      pathId = 'fractions';
    }
    
    if (pathId != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LearningPathScreen(pathId: pathId!),
          transitionsBuilder: (_, a, __, child) => 
            SlideTransition(
              position: a.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
              child: child,
            ),
        ),
      );
    } else {
      // For topics without learning paths, show the generic coming soon message
      widget.onSelect(topic.title);
    }
  }
}

// Removed page indicator dots; vertical layout now handles longer content naturally.

class _TopicCardData {
  final String title;
  final String strand;
  final List<String> topics;
  final IconData icon;
  final IconData strandIcon;
  final String difficulty;

  const _TopicCardData({
    required this.title,
    required this.strand,
    required this.topics,
    required this.icon,
    required this.strandIcon,
    required this.difficulty,
  });
}

class _ModernTopicCard extends StatelessWidget {
  final _TopicCardData data;
  final VoidCallback onTap;
  
  const _ModernTopicCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor(data.difficulty);
    final progress = GameStateController.instance.masteryPercent[data.title] ?? 0.0;
    final isStarted = progress > 0;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
            color: isStarted 
                ? difficultyColor.withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
            width: isStarted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Progress indicator overlay
            if (isStarted)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [difficultyColor, difficultyColor.withOpacity(0.3)],
                      stops: [progress, progress],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and progress ring
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: difficultyColor.withOpacity(0.15),
                        ),
                        child: Icon(
                          data.icon,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data.strand,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      // Progress Ring
                      _ProgressRing(
                        progress: progress,
                        size: 32,
                        strokeWidth: 3,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        progressColor: difficultyColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Topics preview
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < (data.topics.length > 3 ? 3 : data.topics.length); i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white60,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    data.topics[i],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (data.topics.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+${data.topics.length - 3} more topics',
                              style: TextStyle(
                                color: difficultyColor.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Footer - simplified
                  Row(
                    children: [
                      Text(
                        '${data.topics.length} topics',
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
                            Text(
                              isStarted ? 'Continue' : 'Start',
                              style: TextStyle(
                                color: difficultyColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isStarted ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                              color: difficultyColor,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

IconData _iconForStrand(String strand) {
  final s = strand.toLowerCase();
  if (s.contains('number') || s.contains('algebra')) return Icons.calculate_rounded;
  if (s.contains('geometry') || s.contains('measurement')) return Icons.pentagon_rounded;
  if (s.contains('statistics')) return Icons.pie_chart_rounded;
  return Icons.school_rounded;
}

IconData _iconForSubStrand(String title) {
  final t = title.toLowerCase();
  if (t.contains('fraction')) return Icons.looks_3_rounded;
  if (t.contains('percentage')) return Icons.percent_rounded;
  if (t.contains('ratio')) return Icons.device_hub_rounded;
  if (t.contains('speed') || t.contains('rate')) return Icons.speed_rounded;
  if (t.contains('algebra')) return Icons.functions_rounded;
  if (t.contains('area') || t.contains('volume') || t.contains('circle')) return Icons.circle_outlined;
  if (t.contains('pie')) return Icons.pie_chart_outline_rounded;
  return Icons.auto_awesome_rounded;
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  const _ProgressRing({
    required this.progress,
    required this.size,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: backgroundColor,
                width: strokeWidth,
              ),
            ),
          ),
          // Progress circle
          if (progress > 0)
            Container(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: strokeWidth,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          // Center content
          Center(
            child: progress > 0
                ? Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.25,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white60,
                    size: size * 0.4,
                  ),
          ),
        ],
      ),
    );
  }
}
