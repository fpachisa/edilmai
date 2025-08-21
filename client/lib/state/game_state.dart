import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'game_state_persistence.dart';
import 'game_state_store_firestore.dart';
import '../config.dart';

class GameStateController extends ChangeNotifier {
  static final GameStateController instance = GameStateController._();
  GameStateController._();
  
  // Use Firestore in production, local storage in development
  late final GameStateStore _store;
  FirestoreGameStateStore? _firestoreStore;
  StreamSubscription? _gameStateStreamSubscription;
  StreamSubscription? _connectivitySubscription;

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
    
    // Initialize appropriate store based on configuration
    _initializeStore();
    
    final snap = await _store.load();
    if (snap != null) {
      _applySnapshot(snap);
    }
    
    // Set up real-time sync if using Firestore
    _setupRealTimeSync();
    
    // Monitor connectivity for offline/online sync
    _setupConnectivityMonitoring();
    
    _loaded = true;
  }

  void _initializeStore() {
    if (kUseFirebaseAuth) {
      // Production mode: Use Firestore with local fallback
      _firestoreStore = FirestoreGameStateStore();
      _store = _firestoreStore!;
      print('GameStateController: Using Firestore store (production mode)');
    } else {
      // Development mode: Use local storage
      _store = createDefaultGameStateStore();
      print('GameStateController: Using local store (development mode)');
    }
  }

  void _applySnapshot(GameStateSnapshot snap) {
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

  void _setupRealTimeSync() {
    if (_firestoreStore == null) return;
    
    // Listen to real-time updates from Firestore
    _gameStateStreamSubscription = _firestoreStore!.getGameStateStream().listen(
      (snapshot) {
        if (snapshot != null && _loaded) {
          print('GameStateController: Received real-time game state update');
          _applySnapshot(snapshot);
        }
      },
      onError: (error) {
        print('GameStateController: Error in real-time sync: $error');
      },
    );
  }

  void _setupConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        if (result != ConnectivityResult.none && _firestoreStore != null) {
          print('GameStateController: Back online, forcing sync');
          _firestoreStore!.forcSync();
        }
      },
    );
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

  /// Force sync to cloud (useful for critical updates)
  Future<bool> forceCloudSync() async {
    if (_firestoreStore == null) return false;
    return await _firestoreStore!.forcSync();
  }

  /// Check if using cloud storage
  bool get isUsingCloudStorage => _firestoreStore != null;

  /// Get current game state snapshot
  GameStateSnapshot get currentSnapshot => GameStateSnapshot(
    xp: _xp,
    streakDays: _streakDays,
    sessions: _sessions,
    steps: _steps,
    correct: _correct,
    badges: {..._badges},
    masteryPct: {for (final e in _mastery.entries) e.key: e.value.pct},
    lastActiveIso: _lastActiveDay?.toIso8601String(),
  );

  /// Clean up resources
  @override
  void dispose() {
    _gameStateStreamSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _firestoreStore?.dispose();
    super.dispose();
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
