import 'dart:convert';
import 'package:flutter/material.dart';
import '../api_client.dart';
import '../config.dart';
import 'tutor_screen.dart';
import '../ui/app_theme.dart';
import '../state/game_state.dart';
import '../ui/shimmer.dart';
import '../ui/mastery_ring.dart';
import '../data/syllabus.dart';

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
    setState(() {
      _loadingFeed = true;
      _feedError = null;
    });
    try {
      final data = await api.getHomeFeed(learnerId: 'demo');
      if (!mounted) return;
      setState(() {
        _feed = data;
        _feedError = null;
      });
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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Row(
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
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: GameStateController.instance,
                  builder: (context, _) => XPBar(xp: GameStateController.instance.xp, goal: 100),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              // Topics mastery rings row
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Topics', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 128,
                      child: AnimatedBuilder(
                        animation: GameStateController.instance,
                        builder: (context, _) {
                          final m = GameStateController.instance.masteryPercent;
                          final entries = m.entries.toList()
                            ..sort((a, b) => (b.value).compareTo(a.value));
                          final items = entries.isEmpty
                              ? [
                                  const _TopicRingData('Algebraic Expressions', 0.0),
                                  const _TopicRingData('Equations', 0.0),
                                  const _TopicRingData('Word Problems', 0.0),
                                ]
                              : entries.map((e) => _TopicRingData(e.key, e.value)).toList();

                          final count = items.length > 8 ? 8 : items.length;
                          return ListView.separated(
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
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
              SliverToBoxAdapter(
                child: Text('Daily Quest', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: Builder(builder: (context) {
                  if (_loadingFeed) {
                    return const _QuestCardSkeleton();
                  } else if (_feed == null) {
                    return Column(children: [
                      if (_feedError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ErrorBanner(message: _feedError!, onRetry: _busy ? null : _loadFeed),
                        ),
                      _QuestCard(
                        title: 'Algebra Starter',
                        subtitle: 'P6 • Expressions • 1–2 mins',
                        color: Colors.indigoAccent,
                        onTap: _busy ? null : _startAlgebraQuest,
                      ),
                    ]);
                  } else {
                    return Column(children: [
                      if (_feed!["continue"] != null)
                        _QuestCard(
                          title: _feed!["continue"]["title"] ?? 'Continue',
                          subtitle: 'Resume • ${(_feed!["continue"]["est_seconds"] ?? 60)}s',
                          color: Colors.tealAccent,
                          onTap: _busy ? null : () => _continueSession(_feed!["continue"]["session_id"] as String?),
                        ),
                      if ((_feed!["daily_quest"] as List).isNotEmpty)
                        _QuestCard(
                          title: (_feed!["daily_quest"][0]["title"] as String?) ?? 'Daily Quest',
                          subtitle: '${_feed!["daily_quest"][0]["topic"]} • ${(_feed!["daily_quest"][0]["est_seconds"] ?? 60)}s',
                          color: Colors.indigoAccent,
                          onTap: _busy ? null : () => _startSpecificItem(_feed!["daily_quest"][0]["id"] as String?),
                        ),
                    ]);
                  }
                }),
              ),
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
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Browse Syllabus', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: kP6Syllabus.length,
            itemBuilder: (context, i) {
              final section = kP6Syllabus[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Glass(
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_iconForStrand(section.strand), color: Colors.white70),
                          const SizedBox(width: 8),
                          Expanded(child: Text(section.strand, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, j) {
                            final ss = section.subStrands[j];
                            return _SubStrandTile(
                              title: ss.title,
                              bullets: ss.subTopics.take(3).toList(),
                              icon: _iconForSubStrand(ss.title),
                              onTap: () => widget.onSelect(ss.title),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemCount: section.subStrands.length,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(kP6Syllabus.length, (i) => _Dot(active: i == _page)),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 10 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white30,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _SubStrandTile extends StatelessWidget {
  final String title;
  final List<String> bullets;
  final IconData icon;
  final VoidCallback onTap;
  const _SubStrandTile({required this.title, required this.bullets, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(colors: [
      Theme.of(context).colorScheme.primary.withOpacity(0.8),
      Colors.cyanAccent.withOpacity(0.6),
    ]);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)],
          ),
          border: GradientBoxBorder(gradient: gradient, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final b in bullets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Colors.white60)),
                            Expanded(child: Text(b, style: const TextStyle(color: Colors.white70))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: FilledButton.tonal(
                onPressed: onTap,
                child: const Text('Explore'),
              ),
            )
          ],
        ),
      ),
    );
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
