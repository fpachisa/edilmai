import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/firestore_service.dart';
import '../state/active_learner.dart';
import '../config.dart';

/// Real-time progress tracking data model
class ProgressSnapshot {
  final String learnerId;
  final Map<String, int> topicProgress;
  final Map<String, double> skillMastery;
  final Map<String, DateTime> lastTopicAccess;
  final int totalSessionsCompleted;
  final int totalStepsCompleted;
  final int totalCorrectAnswers;
  final DateTime lastUpdated;

  ProgressSnapshot({
    required this.learnerId,
    required this.topicProgress,
    required this.skillMastery,
    required this.lastTopicAccess,
    required this.totalSessionsCompleted,
    required this.totalStepsCompleted,
    required this.totalCorrectAnswers,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'learnerId': learnerId,
    'topicProgress': topicProgress,
    'skillMastery': skillMastery,
    'lastTopicAccess': lastTopicAccess.map((k, v) => MapEntry(k, v.toIso8601String())),
    'totalSessionsCompleted': totalSessionsCompleted,
    'totalStepsCompleted': totalStepsCompleted,
    'totalCorrectAnswers': totalCorrectAnswers,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  static ProgressSnapshot fromJson(Map<String, dynamic> json) => ProgressSnapshot(
    learnerId: json['learnerId'] as String,
    topicProgress: Map<String, int>.from(json['topicProgress'] ?? {}),
    skillMastery: Map<String, double>.from(json['skillMastery'] ?? {}),
    lastTopicAccess: (json['lastTopicAccess'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, DateTime.parse(v as String))),
    totalSessionsCompleted: json['totalSessionsCompleted'] as int? ?? 0,
    totalStepsCompleted: json['totalStepsCompleted'] as int? ?? 0,
    totalCorrectAnswers: json['totalCorrectAnswers'] as int? ?? 0,
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  );
}

/// Service for tracking learner progress in real-time
class ProgressTrackingService {
  static final ProgressTrackingService _instance = ProgressTrackingService._internal();
  factory ProgressTrackingService() => _instance;
  ProgressTrackingService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  SharedPreferences? _prefs;
  ProgressSnapshot? _currentProgress;
  Timer? _syncTimer;
  StreamController<ProgressSnapshot>? _progressController;
  StreamSubscription? _connectivitySubscription;
  bool _isOnline = true;
  List<ProgressSnapshot> _pendingSyncQueue = [];
  
  static const String _progressKey = 'progress_snapshot';
  static const String _pendingSyncKey = 'pending_sync_queue';
  static const Duration _syncInterval = Duration(seconds: 30);

  /// Initialize the progress tracking service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _firestoreService.initialize();
    
    _progressController = StreamController<ProgressSnapshot>.broadcast();
    
    // Load existing progress and pending sync queue
    await _loadProgress();
    await _loadPendingSyncQueue();
    
    // Set up connectivity monitoring
    _setupConnectivityMonitoring();
    
    // Start periodic sync
    _startPeriodicSync();
  }

  /// Load progress from local storage and Firestore
  Future<void> _loadProgress() async {
    final learnerId = ActiveLearner.instance.id;
    if (learnerId == null) return;

    try {
      ProgressSnapshot? progress;

      // Try loading from Firestore in production mode
      if (kUseFirebaseAuth) {
        progress = await _loadFromFirestore(learnerId);
      }

      // Fallback to local storage
      progress ??= await _loadLocally();

      // Initialize with default if no progress found
      progress ??= ProgressSnapshot(
        learnerId: learnerId,
        topicProgress: {},
        skillMastery: {},
        lastTopicAccess: {},
        totalSessionsCompleted: 0,
        totalStepsCompleted: 0,
        totalCorrectAnswers: 0,
        lastUpdated: DateTime.now(),
      );

      _currentProgress = progress;
      _notifyListeners();
      
      print('ProgressTrackingService: Loaded progress for learner: $learnerId');
    } catch (e) {
      print('ProgressTrackingService: Error loading progress: $e');
    }
  }

  /// Save progress locally
  Future<void> _saveLocally(ProgressSnapshot progress) async {
    try {
      final json = jsonEncode(progress.toJson());
      await _prefs?.setString(_progressKey, json);
    } catch (e) {
      print('ProgressTrackingService: Error saving locally: $e');
    }
  }

  /// Load progress locally
  Future<ProgressSnapshot?> _loadLocally() async {
    try {
      final json = _prefs?.getString(_progressKey);
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return ProgressSnapshot.fromJson(data);
      }
    } catch (e) {
      print('ProgressTrackingService: Error loading locally: $e');
    }
    return null;
  }

  /// Save progress to Firestore
  Future<void> _saveToFirestore(ProgressSnapshot progress) async {
    try {
      await _firestoreService.updateLearnerProgress(progress.learnerId, {
        'performance_stats': {
          'total_sessions': progress.totalSessionsCompleted,
          'total_steps': progress.totalStepsCompleted,
          'total_correct': progress.totalCorrectAnswers,
        },
        'topic_progress': progress.topicProgress,
        'mastery_scores': progress.skillMastery,
        'last_topic_access': progress.lastTopicAccess
            .map((k, v) => MapEntry(k, v.toIso8601String())),
        'progress_updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('ProgressTrackingService: Error saving to Firestore: $e');
    }
  }

  /// Load progress from Firestore
  Future<ProgressSnapshot?> _loadFromFirestore(String learnerId) async {
    try {
      final learnerStream = _firestoreService.getLearnerStream(learnerId);
      final learnerData = await learnerStream.first;
      
      if (learnerData == null) return null;

      final performanceStats = Map<String, dynamic>.from(learnerData['performance_stats'] ?? {});
      final topicProgress = Map<String, int>.from(learnerData['topic_progress'] ?? {});
      final skillMastery = Map<String, double>.from(learnerData['mastery_scores'] ?? {});
      final lastTopicAccessRaw = Map<String, dynamic>.from(learnerData['last_topic_access'] ?? {});
      
      final lastTopicAccess = <String, DateTime>{};
      for (final entry in lastTopicAccessRaw.entries) {
        try {
          lastTopicAccess[entry.key] = DateTime.parse(entry.value as String);
        } catch (_) {
          // Skip invalid dates
        }
      }

      return ProgressSnapshot(
        learnerId: learnerId,
        topicProgress: topicProgress,
        skillMastery: skillMastery,
        lastTopicAccess: lastTopicAccess,
        totalSessionsCompleted: performanceStats['total_sessions'] as int? ?? 0,
        totalStepsCompleted: performanceStats['total_steps'] as int? ?? 0,
        totalCorrectAnswers: performanceStats['total_correct'] as int? ?? 0,
        lastUpdated: DateTime.tryParse(learnerData['progress_updated_at'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      print('ProgressTrackingService: Error loading from Firestore: $e');
      return null;
    }
  }

  /// Set up connectivity monitoring
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        final wasOnline = _isOnline;
        _isOnline = result != ConnectivityResult.none;
        
        if (!wasOnline && _isOnline) {
          print('ProgressTrackingService: Back online, syncing pending changes');
          _syncPendingQueue();
        } else if (wasOnline && !_isOnline) {
          print('ProgressTrackingService: Gone offline, will queue changes');
        }
      },
    );
  }

  /// Load pending sync queue from local storage
  Future<void> _loadPendingSyncQueue() async {
    try {
      final queueJson = _prefs?.getString(_pendingSyncKey);
      if (queueJson != null) {
        final queueData = jsonDecode(queueJson) as List;
        _pendingSyncQueue = queueData
            .map((item) => ProgressSnapshot.fromJson(item as Map<String, dynamic>))
            .toList();
        print('ProgressTrackingService: Loaded ${_pendingSyncQueue.length} pending sync items');
      }
    } catch (e) {
      print('ProgressTrackingService: Error loading pending sync queue: $e');
      _pendingSyncQueue = [];
    }
  }

  /// Save pending sync queue to local storage
  Future<void> _savePendingSyncQueue() async {
    try {
      final queueJson = jsonEncode(_pendingSyncQueue.map((item) => item.toJson()).toList());
      await _prefs?.setString(_pendingSyncKey, queueJson);
    } catch (e) {
      print('ProgressTrackingService: Error saving pending sync queue: $e');
    }
  }

  /// Add progress to pending sync queue
  Future<void> _addToPendingQueue(ProgressSnapshot progress) async {
    // Remove any existing entry for the same learner (keep only the latest)
    _pendingSyncQueue.removeWhere((item) => item.learnerId == progress.learnerId);
    _pendingSyncQueue.add(progress);
    
    // Limit queue size to prevent excessive memory usage
    if (_pendingSyncQueue.length > 10) {
      _pendingSyncQueue.removeAt(0);
    }
    
    await _savePendingSyncQueue();
  }

  /// Sync pending queue to Firestore when back online
  Future<void> _syncPendingQueue() async {
    if (!_isOnline || _pendingSyncQueue.isEmpty) return;
    
    final itemsToSync = List<ProgressSnapshot>.from(_pendingSyncQueue);
    _pendingSyncQueue.clear();
    await _savePendingSyncQueue();
    
    for (final progress in itemsToSync) {
      try {
        await _saveToFirestore(progress);
        print('ProgressTrackingService: Successfully synced pending progress for ${progress.learnerId}');
      } catch (e) {
        print('ProgressTrackingService: Failed to sync pending progress: $e');
        // Re-add to queue for retry
        _pendingSyncQueue.add(progress);
      }
    }
    
    if (_pendingSyncQueue.isNotEmpty) {
      await _savePendingSyncQueue();
    }
  }

  /// Start periodic sync to Firestore
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _syncToCloud();
    });
  }

  /// Sync progress to cloud
  Future<void> _syncToCloud() async {
    if (_currentProgress != null && kUseFirebaseAuth) {
      if (_isOnline) {
        try {
          await _saveToFirestore(_currentProgress!);
          print('ProgressTrackingService: Synced progress to Firestore');
        } catch (e) {
          print('ProgressTrackingService: Sync failed, adding to queue: $e');
          await _addToPendingQueue(_currentProgress!);
        }
      } else {
        print('ProgressTrackingService: Offline, adding progress to sync queue');
        await _addToPendingQueue(_currentProgress!);
      }
    }
  }

  /// Record session completion
  Future<void> recordSessionCompleted({
    required String topic,
    required int stepsCompleted,
    required int correctAnswers,
    required String skill,
    required double skillAccuracy,
  }) async {
    if (_currentProgress == null) return;

    try {
      final updatedProgress = ProgressSnapshot(
        learnerId: _currentProgress!.learnerId,
        topicProgress: {
          ..._currentProgress!.topicProgress,
          topic: (_currentProgress!.topicProgress[topic] ?? 0) + 1,
        },
        skillMastery: {
          ..._currentProgress!.skillMastery,
          skill: skillAccuracy,
        },
        lastTopicAccess: {
          ..._currentProgress!.lastTopicAccess,
          topic: DateTime.now(),
        },
        totalSessionsCompleted: _currentProgress!.totalSessionsCompleted + 1,
        totalStepsCompleted: _currentProgress!.totalStepsCompleted + stepsCompleted,
        totalCorrectAnswers: _currentProgress!.totalCorrectAnswers + correctAnswers,
        lastUpdated: DateTime.now(),
      );

      _currentProgress = updatedProgress;
      await _saveLocally(updatedProgress);
      _notifyListeners();

      // Immediate sync to cloud for session completion
      if (kUseFirebaseAuth) {
        if (_isOnline) {
          try {
            await _saveToFirestore(updatedProgress);
          } catch (e) {
            print('ProgressTrackingService: Failed to sync session completion, queuing: $e');
            await _addToPendingQueue(updatedProgress);
          }
        } else {
          await _addToPendingQueue(updatedProgress);
        }
      }

      print('ProgressTrackingService: Recorded session completion for topic: $topic');
    } catch (e) {
      print('ProgressTrackingService: Error recording session completion: $e');
    }
  }

  /// Record step progress
  Future<void> recordStepProgress({
    required String topic,
    required String skill,
    required bool correct,
  }) async {
    if (_currentProgress == null) return;

    try {
      final updatedProgress = ProgressSnapshot(
        learnerId: _currentProgress!.learnerId,
        topicProgress: _currentProgress!.topicProgress,
        skillMastery: _currentProgress!.skillMastery,
        lastTopicAccess: {
          ..._currentProgress!.lastTopicAccess,
          topic: DateTime.now(),
        },
        totalSessionsCompleted: _currentProgress!.totalSessionsCompleted,
        totalStepsCompleted: _currentProgress!.totalStepsCompleted + 1,
        totalCorrectAnswers: _currentProgress!.totalCorrectAnswers + (correct ? 1 : 0),
        lastUpdated: DateTime.now(),
      );

      _currentProgress = updatedProgress;
      await _saveLocally(updatedProgress);
      _notifyListeners();

      print('ProgressTrackingService: Recorded step progress for topic: $topic, correct: $correct');
    } catch (e) {
      print('ProgressTrackingService: Error recording step progress: $e');
    }
  }

  /// Get current progress snapshot
  ProgressSnapshot? get currentProgress => _currentProgress;

  /// Get real-time progress stream
  Stream<ProgressSnapshot> get progressStream {
    _progressController ??= StreamController<ProgressSnapshot>.broadcast();
    return _progressController!.stream;
  }

  /// Notify listeners of progress changes
  void _notifyListeners() {
    if (_currentProgress != null && _progressController != null) {
      _progressController!.add(_currentProgress!);
    }
  }

  /// Force immediate sync to cloud
  Future<void> forceSync() async {
    await _syncToCloud();
  }

  /// Get progress summary for a topic
  Map<String, dynamic> getTopicSummary(String topic) {
    if (_currentProgress == null) {
      return {
        'sessionsCompleted': 0,
        'lastAccessed': null,
        'overallAccuracy': 0.0,
      };
    }

    return {
      'sessionsCompleted': _currentProgress!.topicProgress[topic] ?? 0,
      'lastAccessed': _currentProgress!.lastTopicAccess[topic],
      'overallAccuracy': _currentProgress!.totalStepsCompleted > 0 
          ? _currentProgress!.totalCorrectAnswers / _currentProgress!.totalStepsCompleted
          : 0.0,
    };
  }

  /// Clean up resources
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _progressController?.close();
    _syncTimer = null;
    _connectivitySubscription = null;
    _progressController = null;
    _currentProgress = null;
    _pendingSyncQueue.clear();
  }
}