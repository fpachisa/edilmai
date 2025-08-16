import 'package:flutter/foundation.dart';
import 'game_state_persistence.dart';

class GameStateController extends ChangeNotifier {
  static final GameStateController instance = GameStateController._();
  GameStateController._();
  final GameStateStore _store = createDefaultGameStateStore();

  // Core gamification
  int _xp = 0;
  int get xp => _xp;

  int _streakDays = 0;
  int get streakDays => _streakDays;

  int _sessions = 0;
  int get sessions => _sessions;

  int _steps = 0;
  int get steps => _steps;

  int _correct = 0;
  int get correct => _correct;

  // Simple mastery by skill/topic
  final Map<String, _SkillProgress> _mastery = {};
  Map<String, double> get masteryPercent => {
        for (final e in _mastery.entries) e.key: e.value.pct,
      };

  // Badges
  final Set<String> _badges = <String>{};
  Set<String> get badges => _badges;

  // Tracking for per-prompt attempts to award no-hint bonus
  int _attemptsSincePrompt = 0;
  DateTime? _lastActiveDay; // for streaks
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final snap = await _store.load();
    if (snap != null) {
      _xp = snap.xp;
      _streakDays = snap.streakDays;
      _sessions = snap.sessions;
      _steps = snap.steps;
      _correct = snap.correct;
      _badges
        ..clear()
        ..addAll(snap.badges);
      _mastery
        ..clear()
        ..addAll({
          for (final e in snap.masteryPct.entries) e.key: _SkillProgress.fromPct(e.value),
        });
      if (snap.lastActiveIso != null) {
        try {
          _lastActiveDay = DateTime.tryParse(snap.lastActiveIso!);
        } catch (_) {}
      }
      notifyListeners();
    }
    _loaded = true;
  }

  Future<void> _save() async {
    if (!_loaded) return; // avoid saving initial zero state before load
    final snap = GameStateSnapshot(
      xp: _xp,
      streakDays: _streakDays,
      sessions: _sessions,
      steps: _steps,
      correct: _correct,
      badges: {..._badges},
      masteryPct: {for (final e in _mastery.entries) e.key: e.value.pct},
      lastActiveIso: _lastActiveDay?.toIso8601String(),
    );
    await _store.save(snap);
  }

  // Hydrate from server profile (non-authoritative fallback to local when missing)
  void hydrate({int? xp, int? streakDays, Map<String, double>? masteryPct, Iterable<String>? badges}) {
    if (xp != null) _xp = xp;
    if (streakDays != null) _streakDays = streakDays;
    if (badges != null) {
      _badges
        ..clear()
        ..addAll(badges);
    }
    if (masteryPct != null) {
      _mastery
        ..clear()
        ..addAll({for (final e in masteryPct.entries) e.key: _SkillProgress.fromPct(e.value)});
    }
    notifyListeners();
    _save();
  }

  void onPromptShown() {
    _attemptsSincePrompt = 0;
    _save();
  }

  void recordAttempt({required bool correct, String? skill}) {
    _attemptsSincePrompt += 1;
    _steps += 1;
    if (skill != null) {
      final sp = _mastery.putIfAbsent(skill, () => _SkillProgress());
      sp.total += 1;
    }
    if (correct) {
      _correct += 1;
      if (skill != null) {
        _mastery[skill]!.correct += 1;
      }
    }
    notifyListeners();
    _save();
  }

  int applyXpForCorrect({required int baseXp}) {
    int bonus = _attemptsSincePrompt == 1 ? 2 : 0; // treat first-try as no-hint bonus
    _xp += baseXp + bonus;
    if (_correct == 1) {
      _badges.add('First Steps');
    }
    if (bonus > 0) {
      _badges.add('No Hints');
    }
    _updateStreak();
    _checkStreakBadges();
    notifyListeners();
    _save();
    return baseXp + bonus;
  }

  void onItemCompleted({String? topic}) {
    _sessions += 1;
    if ((topic ?? '').toLowerCase().contains('algebra')) {
      _badges.add('Algebra Start');
    }
    notifyListeners();
    _save();
  }

  void _updateStreak() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (_lastActiveDay == null) {
      _streakDays = 1;
    } else {
      final last = DateTime(_lastActiveDay!.year, _lastActiveDay!.month, _lastActiveDay!.day);
      final diff = todayDate.difference(last).inDays;
      if (diff == 0) {
        // same day, keep streak
      } else if (diff == 1) {
        _streakDays += 1;
      } else {
        _streakDays = 1;
      }
    }
    _lastActiveDay = todayDate;
    _save();
  }

  void _checkStreakBadges() {
    if (_streakDays >= 3) _badges.add('Streak 3');
  }
}

class _SkillProgress {
  int correct = 0;
  int total = 0;
  double get pct => total == 0 ? 0.0 : correct / total;
  _SkillProgress();
  _SkillProgress.fromPct(double p) {
    correct = (p * 1000).round();
    total = 1000;
  }
}
