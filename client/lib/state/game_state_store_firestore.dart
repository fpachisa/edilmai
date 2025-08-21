import 'dart:async';
import 'game_state_types.dart';
import '../services/firestore_service.dart';
import '../state/active_learner.dart';

/// Firestore-backed GameStateStore for production persistence
class FirestoreGameStateStore implements GameStateStore {
  final FirestoreService _firestoreService = FirestoreService();
  GameStateSnapshot? _cachedSnapshot;
  Timer? _syncTimer;
  
  /// Cache duration for local snapshot (to avoid excessive Firestore reads)
  static const Duration _cacheDuration = Duration(minutes: 5);
  DateTime? _lastCacheUpdate;

  @override
  Future<GameStateSnapshot?> load() async {
    try {
      // Initialize Firestore if not already done
      await _firestoreService.initialize();
      
      final learnerId = ActiveLearner.instance.id;
      if (learnerId == null) {
        print('FirestoreGameStateStore: No active learner, cannot load game state');
        return null;
      }

      // Check cache first
      if (_cachedSnapshot != null && 
          _lastCacheUpdate != null && 
          DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
        print('FirestoreGameStateStore: Returning cached game state');
        return _cachedSnapshot;
      }

      // Load from Firestore
      print('FirestoreGameStateStore: Loading game state from Firestore for learner: $learnerId');
      final snapshot = await _firestoreService.loadGameState(learnerId);
      
      // Update cache
      _cachedSnapshot = snapshot;
      _lastCacheUpdate = DateTime.now();
      
      // Set up periodic sync if not already running
      _startPeriodicSync();
      
      return snapshot;
    } catch (e) {
      print('FirestoreGameStateStore: Error loading game state: $e');
      // Return cached data if available, otherwise null
      return _cachedSnapshot;
    }
  }

  @override
  Future<void> save(GameStateSnapshot snapshot) async {
    try {
      final learnerId = ActiveLearner.instance.id;
      if (learnerId == null) {
        print('FirestoreGameStateStore: No active learner, cannot save game state');
        return;
      }

      // Update cache immediately
      _cachedSnapshot = snapshot;
      _lastCacheUpdate = DateTime.now();

      // Sync to Firestore
      print('FirestoreGameStateStore: Syncing game state to Firestore for learner: $learnerId');
      await _firestoreService.syncGameState(learnerId, snapshot);
      
    } catch (e) {
      print('FirestoreGameStateStore: Error saving game state: $e');
      // Store failed sync for retry (implement if needed)
      _scheduleRetry(snapshot);
    }
  }

  /// Start periodic sync to ensure data consistency
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _periodicSync();
    });
  }

  /// Perform periodic sync to keep local and remote data in sync
  Future<void> _periodicSync() async {
    try {
      final learnerId = ActiveLearner.instance.id;
      if (learnerId == null || _cachedSnapshot == null) return;

      // Load fresh data from Firestore
      final remoteSnapshot = await _firestoreService.loadGameState(learnerId);
      
      if (remoteSnapshot != null) {
        // Compare timestamps to determine which data is newer
        final localTime = DateTime.tryParse(_cachedSnapshot!.lastActiveIso ?? '');
        final remoteTime = DateTime.tryParse(remoteSnapshot.lastActiveIso ?? '');
        
        // If remote data is newer, update cache
        if (remoteTime != null && 
            (localTime == null || remoteTime.isAfter(localTime))) {
          print('FirestoreGameStateStore: Remote data is newer, updating cache');
          _cachedSnapshot = remoteSnapshot;
          _lastCacheUpdate = DateTime.now();
        }
      }
    } catch (e) {
      print('FirestoreGameStateStore: Error during periodic sync: $e');
    }
  }

  /// Schedule retry for failed sync operations
  void _scheduleRetry(GameStateSnapshot snapshot) {
    Timer(const Duration(seconds: 30), () async {
      try {
        final learnerId = ActiveLearner.instance.id;
        if (learnerId != null) {
          await _firestoreService.syncGameState(learnerId, snapshot);
          print('FirestoreGameStateStore: Retry sync successful');
        }
      } catch (e) {
        print('FirestoreGameStateStore: Retry sync failed: $e');
      }
    });
  }

  /// Get real-time stream of game state updates
  Stream<GameStateSnapshot?> getGameStateStream() {
    final learnerId = ActiveLearner.instance.id;
    if (learnerId == null) {
      return Stream.value(null);
    }

    return _firestoreService.getLearnerStream(learnerId).map((data) {
      if (data == null) return null;

      final streaks = Map<String, dynamic>.from(data['streaks'] ?? {});
      final performanceStats = Map<String, dynamic>.from(data['performance_stats'] ?? {});
      
      final snapshot = GameStateSnapshot(
        xp: data['xp'] ?? 0,
        streakDays: streaks['current'] ?? 0,
        sessions: performanceStats['total_sessions'] ?? 0,
        steps: performanceStats['total_steps'] ?? 0,
        correct: performanceStats['total_correct'] ?? 0,
        badges: Set<String>.from(data['badges'] ?? []),
        masteryPct: Map<String, double>.from(data['mastery_scores'] ?? {}),
        lastActiveIso: streaks['last_active'],
      );

      // Update cache
      _cachedSnapshot = snapshot;
      _lastCacheUpdate = DateTime.now();

      return snapshot;
    }).handleError((error) {
      print('FirestoreGameStateStore: Error in game state stream: $error');
    });
  }

  /// Force sync to Firestore (useful for critical updates)
  Future<bool> forcSync() async {
    try {
      if (_cachedSnapshot != null) {
        await save(_cachedSnapshot!);
        return true;
      }
      return false;
    } catch (e) {
      print('FirestoreGameStateStore: Force sync failed: $e');
      return false;
    }
  }

  /// Clean up resources
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _cachedSnapshot = null;
    _lastCacheUpdate = null;
  }
}