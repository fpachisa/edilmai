import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_service.dart';
import '../state/game_state_types.dart';

/**
 * Production Firestore Service for PSLE AI Tutor
 * Handles real-time data synchronization, offline support, and error recovery
 */

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  late FirebaseFirestore _firestore;
  final Map<String, StreamSubscription> _activeStreams = {};
  bool _initialized = false;

  /// Initialize Firestore with production settings
  Future<void> initialize() async {
    if (_initialized) return;
    
    _firestore = FirebaseFirestore.instance;
    
    // Configure for offline support
    await _firestore.enablePersistence();
    
    // Set cache size for better performance (100 MB)
    _firestore.settings = const Settings(
      cacheSizeBytes: 100 * 1024 * 1024,
      persistenceEnabled: true,
    );
    
    _initialized = true;
  }

  /// Get current user ID safely
  String? get currentUserId => AuthService.getCurrentUserId();

  // ============ USER MANAGEMENT ============

  /// Create or update user profile
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String name,
    String role = 'parent',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userData = {
        'user_id': userId,
        'email': email,
        'name': name,
        'role': role,
        'profile': {
          'grade_level': 'P6',
          'school': '',
          'location': 'Singapore',
          'preferences': {
            'language': 'en',
            'notifications': true,
            'reports_frequency': 'weekly',
          },
          ...(additionalData ?? {}),
        },
        'children_ids': <String>[],
        'students_ids': <String>[],
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).set(userData, SetOptions(merge: true));
    } catch (e) {
      throw FirestoreServiceException('Failed to create user profile: $e');
    }
  }

  /// Get user profile with real-time updates
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null)
        .handleError((error) {
          print('Error in user profile stream: $error');
        });
  }

  // ============ LEARNER MANAGEMENT ============

  /// Create new learner profile
  Future<String> createLearner({
    required String parentId,
    required String name,
    String gradeLevel = 'P6',
    List<String> subjects = const ['maths'],
  }) async {
    try {
      final learnerId = _firestore.collection('learners').doc().id;
      
      final learnerData = {
        'learner_id': learnerId,
        'parent_id': parentId,
        'teacher_ids': <String>[],
        
        // Profile
        'name': name,
        'grade_level': gradeLevel,
        'subjects': subjects,
        'learning_style': 'mixed',
        
        // Progress
        'xp': 0,
        'level': 1,
        'streaks': {
          'current': 0,
          'best': 0,
          'last_active': null,
        },
        'badges': <String>[],
        'completed_items': <String>[],
        'mastery_scores': {
          'algebra': 0.0,
          'fractions': 0.0,
          'percentage': 0.0,
          'ratio': 0.0,
          'speed': 0.0,
          'geometry': 0.0,
          'statistics': 0.0,
        },
        
        // Session management
        'current_session_id': null,
        'total_sessions': 0,
        'total_time_spent': 0,
        
        // Analytics
        'performance_stats': {
          'total_problems_attempted': 0,
          'total_problems_correct': 0,
          'accuracy_rate': 0.0,
          'average_attempts_per_problem': 1.0,
          'hint_usage_rate': 0.0,
        },
        'misconceptions': <String, dynamic>{},
        'learning_insights': <Map<String, dynamic>>[],
        
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Create learner document
      await _firestore.collection('learners').doc(learnerId).set(learnerData);
      
      // Add learner to parent's children list
      await _firestore.collection('users').doc(parentId).update({
        'children_ids': FieldValue.arrayUnion([learnerId]),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      return learnerId;
    } catch (e) {
      throw FirestoreServiceException('Failed to create learner: $e');
    }
  }

  /// Get learner profile with real-time updates
  Stream<Map<String, dynamic>?> getLearnerStream(String learnerId) {
    return _firestore
        .collection('learners')
        .doc(learnerId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null)
        .handleError((error) {
          print('Error in learner stream: $error');
        });
  }

  /// Get all learners for a parent
  Stream<List<Map<String, dynamic>>> getParentLearnersStream(String parentId) {
    return _firestore
        .collection('learners')
        .where('parent_id', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
          print('Error in parent learners stream: $error');
        });
  }

  /// Update learner progress
  Future<void> updateLearnerProgress(String learnerId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = FieldValue.serverTimestamp();
      await _firestore.collection('learners').doc(learnerId).update(updates);
    } catch (e) {
      throw FirestoreServiceException('Failed to update learner progress: $e');
    }
  }

  /// Add XP to learner
  Future<void> addXP(String learnerId, int amount) async {
    try {
      await _firestore.collection('learners').doc(learnerId).update({
        'xp': FieldValue.increment(amount),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirestoreServiceException('Failed to add XP: $e');
    }
  }

  /// Mark item as completed
  Future<void> markItemCompleted(String learnerId, String itemId, String subject) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final learnerRef = _firestore.collection('learners').doc(learnerId);
        final learnerDoc = await transaction.get(learnerRef);
        
        if (!learnerDoc.exists) {
          throw FirestoreServiceException('Learner not found: $learnerId');
        }
        
        final data = learnerDoc.data()!;
        final completedItems = List<String>.from(data['completed_items'] ?? []);
        final masteryScores = Map<String, double>.from(data['mastery_scores'] ?? {});
        
        // Add item if not already completed
        if (!completedItems.contains(itemId)) {
          completedItems.add(itemId);
          
          // Update mastery score (increase by 0.1, max 1.0)
          final currentMastery = masteryScores[subject] ?? 0.0;
          masteryScores[subject] = (currentMastery + 0.1).clamp(0.0, 1.0);
          
          // Calculate new level based on XP
          final currentXP = data['xp'] ?? 0;
          final newLevel = ((currentXP / 100) + 1).floor().clamp(1, 100);
          
          transaction.update(learnerRef, {
            'completed_items': completedItems,
            'mastery_scores': masteryScores,
            'level': newLevel,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw FirestoreServiceException('Failed to mark item completed: $e');
    }
  }

  // ============ SESSION MANAGEMENT ============

  /// Create new tutoring session
  Future<String> createSession({
    required String learnerId,
    required String itemId,
    required String subject,
    required String moduleId,
  }) async {
    try {
      final sessionId = _firestore.collection('sessions').doc().id;
      
      final sessionData = {
        'session_id': sessionId,
        'learner_id': learnerId,
        'item_id': itemId,
        'subject': subject,
        'module_id': moduleId,
        
        // Progress
        'current_step_idx': 0,
        'attempts_current': 0,
        'hints_used': 0,
        'finished': false,
        'success': false,
        
        // Conversation and learning
        'conversation_history': <Map<String, dynamic>>[],
        'learning_insights': <Map<String, dynamic>>[],
        'misconceptions': <String, dynamic>{},
        
        // Performance
        'total_time_spent': 0,
        'steps_completed': <Map<String, dynamic>>[],
        'final_accuracy': 0.0,
        'hint_efficiency': 0.0,
        
        'started_at': FieldValue.serverTimestamp(),
        'completed_at': null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Create session
      await _firestore.collection('sessions').doc(sessionId).set(sessionData);
      
      // Update learner's current session
      await updateLearnerProgress(learnerId, {'current_session_id': sessionId});
      
      return sessionId;
    } catch (e) {
      throw FirestoreServiceException('Failed to create session: $e');
    }
  }

  /// Get session with real-time updates
  Stream<Map<String, dynamic>?> getSessionStream(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null)
        .handleError((error) {
          print('Error in session stream: $error');
        });
  }

  /// Add message to conversation history
  Future<void> addToConversation({
    required String sessionId,
    required String role,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final conversationEntry = {
        'timestamp': FieldValue.serverTimestamp(),
        'role': role,
        'message': message,
        'metadata': metadata ?? {},
      };

      await _firestore.collection('sessions').doc(sessionId).update({
        'conversation_history': FieldValue.arrayUnion([conversationEntry]),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirestoreServiceException('Failed to add conversation entry: $e');
    }
  }

  /// Record misconceptions
  Future<void> recordMisconceptions({
    required String sessionId,
    required List<String> misconceptionTags,
    double confidence = 1.0,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final sessionRef = _firestore.collection('sessions').doc(sessionId);
        final sessionDoc = await transaction.get(sessionRef);
        
        if (!sessionDoc.exists) return;
        
        final data = sessionDoc.data()!;
        final misconceptions = Map<String, dynamic>.from(data['misconceptions'] ?? {});
        
        final now = FieldValue.serverTimestamp();
        
        for (final tag in misconceptionTags) {
          if (!misconceptions.containsKey(tag)) {
            misconceptions[tag] = {
              'count': 0,
              'first_seen': now,
              'last_seen': now,
              'confidence_scores': <double>[],
            };
          }
          
          misconceptions[tag]['count'] = (misconceptions[tag]['count'] ?? 0) + 1;
          misconceptions[tag]['last_seen'] = now;
          misconceptions[tag]['confidence_scores'] = [
            ...List<double>.from(misconceptions[tag]['confidence_scores'] ?? []),
            confidence,
          ];
        }
        
        transaction.update(sessionRef, {
          'misconceptions': misconceptions,
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw FirestoreServiceException('Failed to record misconceptions: $e');
    }
  }

  /// Finish session
  Future<void> finishSession({
    required String sessionId,
    required bool success,
    required double finalAccuracy,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final sessionRef = _firestore.collection('sessions').doc(sessionId);
        final sessionDoc = await transaction.get(sessionRef);
        
        if (!sessionDoc.exists) return;
        
        final sessionData = sessionDoc.data()!;
        final learnerId = sessionData['learner_id'] as String?;
        
        // Update session
        transaction.update(sessionRef, {
          'finished': true,
          'success': success,
          'final_accuracy': finalAccuracy,
          'completed_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        
        // Clear current session from learner
        if (learnerId != null) {
          final learnerRef = _firestore.collection('learners').doc(learnerId);
          transaction.update(learnerRef, {
            'current_session_id': null,
            'total_sessions': FieldValue.increment(1),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw FirestoreServiceException('Failed to finish session: $e');
    }
  }

  // ============ CURRICULUM MANAGEMENT ============

  /// Get curriculum items for a subject
  Stream<List<Map<String, dynamic>>> getCurriculumStream(String subject) {
    return _firestore
        .collection('curriculum')
        .doc(subject)
        .collection('items')
        .orderBy('learn_step')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
          print('Error in curriculum stream: $error');
        });
  }

  /// Get specific curriculum item
  Future<Map<String, dynamic>?> getCurriculumItem(String subject, String itemId) async {
    try {
      final doc = await _firestore
          .collection('curriculum')
          .doc(subject)
          .collection('items')
          .doc(itemId)
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw FirestoreServiceException('Failed to get curriculum item: $e');
    }
  }

  // ============ GAME STATE SYNCHRONIZATION ============

  /// Sync local game state with Firestore
  Future<void> syncGameState(String learnerId, GameStateSnapshot gameState) async {
    try {
      await updateLearnerProgress(learnerId, {
        'xp': gameState.xp,
        'streaks': {
          'current': gameState.streakDays,
          'best': gameState.streakDays,
          'last_active': gameState.lastActiveIso,
        },
        'badges': gameState.badges.toList(),
        'mastery_scores': gameState.masteryPct,
        'performance_stats': {
          'total_sessions': gameState.sessions,
          'total_steps': gameState.steps,
          'total_correct': gameState.correct,
          'accuracy_rate': gameState.steps > 0 ? gameState.correct / gameState.steps : 0.0,
        },
      });
    } catch (e) {
      throw FirestoreServiceException('Failed to sync game state: $e');
    }
  }

  /// Load game state from Firestore
  Future<GameStateSnapshot?> loadGameState(String learnerId) async {
    try {
      final doc = await _firestore.collection('learners').doc(learnerId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      final streaks = Map<String, dynamic>.from(data['streaks'] ?? {});
      final performanceStats = Map<String, dynamic>.from(data['performance_stats'] ?? {});
      
      return GameStateSnapshot(
        xp: data['xp'] ?? 0,
        streakDays: streaks['current'] ?? 0,
        sessions: performanceStats['total_sessions'] ?? 0,
        steps: performanceStats['total_steps'] ?? 0,
        correct: performanceStats['total_correct'] ?? 0,
        badges: Set<String>.from(data['badges'] ?? []),
        masteryPct: Map<String, double>.from(data['mastery_scores'] ?? {}),
        lastActiveIso: streaks['last_active'],
      );
    } catch (e) {
      throw FirestoreServiceException('Failed to load game state: $e');
    }
  }

  // ============ UTILITY METHODS ============

  /// Check Firestore connectivity
  Future<bool> checkConnectivity() async {
    try {
      await _firestore.collection('_health_check').doc('test').set({
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clean up active streams
  void dispose() {
    for (final subscription in _activeStreams.values) {
      subscription.cancel();
    }
    _activeStreams.clear();
  }
}

/// Custom exception for Firestore operations
class FirestoreServiceException implements Exception {
  final String message;
  FirestoreServiceException(this.message);
  
  @override
  String toString() => 'FirestoreServiceException: $message';
}