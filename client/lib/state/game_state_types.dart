class GameStateSnapshot {
  final int xp;
  final int streakDays;
  final int sessions;
  final int steps;
  final int correct;
  final Set<String> badges;
  final Map<String, double> masteryPct; // store as percentages for simplicity
  final String? lastActiveIso;

  GameStateSnapshot({
    required this.xp,
    required this.streakDays,
    required this.sessions,
    required this.steps,
    required this.correct,
    required this.badges,
    required this.masteryPct,
    required this.lastActiveIso,
  });

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'streakDays': streakDays,
        'sessions': sessions,
        'steps': steps,
        'correct': correct,
        'badges': badges.toList(),
        'masteryPct': masteryPct,
        'lastActiveIso': lastActiveIso,
      };

  static GameStateSnapshot fromJson(Map<String, dynamic> json) => GameStateSnapshot(
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
        sessions: (json['sessions'] as num?)?.toInt() ?? 0,
        steps: (json['steps'] as num?)?.toInt() ?? 0,
        correct: (json['correct'] as num?)?.toInt() ?? 0,
        badges: {...((json['badges'] as List?)?.cast<String>() ?? const <String>[])},
        masteryPct: Map<String, double>.from((json['masteryPct'] as Map?) ?? const <String, double>{}),
        lastActiveIso: json['lastActiveIso'] as String?,
      );
}

abstract class GameStateStore {
  Future<GameStateSnapshot?> load();
  Future<void> save(GameStateSnapshot snapshot);
}

