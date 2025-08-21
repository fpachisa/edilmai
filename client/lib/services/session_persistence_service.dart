import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../state/active_learner.dart';
import '../config.dart';

/// Session data model for persistence
class SessionState {
  final String sessionId;
  final String learnerId;
  final String stepId;
  final String itemId;
  final String subject;
  final List<ConversationMessage> conversationHistory;
  final int attempts;
  final DateTime lastActive;
  final bool completed;

  SessionState({
    required this.sessionId,
    required this.learnerId,
    required this.stepId,
    required this.itemId,
    required this.subject,
    required this.conversationHistory,
    required this.attempts,
    required this.lastActive,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'learnerId': learnerId,
    'stepId': stepId,
    'itemId': itemId,
    'subject': subject,
    'conversationHistory': conversationHistory.map((msg) => msg.toJson()).toList(),
    'attempts': attempts,
    'lastActive': lastActive.toIso8601String(),
    'completed': completed,
  };

  static SessionState fromJson(Map<String, dynamic> json) => SessionState(
    sessionId: json['sessionId'] as String,
    learnerId: json['learnerId'] as String,
    stepId: json['stepId'] as String,
    itemId: json['itemId'] as String,
    subject: json['subject'] as String,
    conversationHistory: (json['conversationHistory'] as List)
        .map((msg) => ConversationMessage.fromJson(msg))
        .toList(),
    attempts: json['attempts'] as int,
    lastActive: DateTime.parse(json['lastActive'] as String),
    completed: json['completed'] as bool,
  );
}

/// Conversation message model
class ConversationMessage {
  final String role; // 'user' or 'tutor' or 'system'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ConversationMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  static ConversationMessage fromJson(Map<String, dynamic> json) => ConversationMessage(
    role: json['role'] as String,
    content: json['content'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

/// Service for persisting tutoring sessions
class SessionPersistenceService {
  static final SessionPersistenceService _instance = SessionPersistenceService._internal();
  factory SessionPersistenceService() => _instance;
  SessionPersistenceService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  SharedPreferences? _prefs;
  static const String _sessionKey = 'current_session_state';
  static const Duration _sessionTimeout = Duration(hours: 2);

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _firestoreService.initialize();
  }

  /// Save current session state
  Future<void> saveSessionState(SessionState sessionState) async {
    try {
      final learnerId = ActiveLearner.instance.id;
      if (learnerId == null) return;

      // Always save locally for quick access
      await _saveLocally(sessionState);

      // Save to Firestore in production mode
      if (kUseFirebaseAuth) {
        await _saveToFirestore(sessionState);
      }

      print('SessionPersistenceService: Session state saved for ${sessionState.sessionId}');
    } catch (e) {
      print('SessionPersistenceService: Error saving session state: $e');
    }
  }

  /// Load the most recent session state
  Future<SessionState?> loadSessionState() async {
    try {
      final learnerId = ActiveLearner.instance.id;
      if (learnerId == null) return null;

      SessionState? sessionState;

      // Try loading from Firestore first in production mode
      if (kUseFirebaseAuth) {
        sessionState = await _loadFromFirestore(learnerId);
      }

      // Fallback to local storage
      sessionState ??= await _loadLocally();

      // Check if session is still valid (not timed out)
      if (sessionState != null && _isSessionValid(sessionState)) {
        print('SessionPersistenceService: Loaded valid session ${sessionState.sessionId}');
        return sessionState;
      } else if (sessionState != null) {
        print('SessionPersistenceService: Session ${sessionState.sessionId} has expired');
        await clearSessionState(); // Clean up expired session
      }

      return null;
    } catch (e) {
      print('SessionPersistenceService: Error loading session state: $e');
      return null;
    }
  }

  /// Clear current session state
  Future<void> clearSessionState() async {
    try {
      // Clear local storage
      await _prefs?.remove(_sessionKey);

      // Clear from Firestore in production mode
      if (kUseFirebaseAuth) {
        final learnerId = ActiveLearner.instance.id;
        if (learnerId != null) {
          await _firestoreService.updateLearnerProgress(learnerId, {
            'current_session_id': null,
          });
        }
      }

      print('SessionPersistenceService: Session state cleared');
    } catch (e) {
      print('SessionPersistenceService: Error clearing session state: $e');
    }
  }

  /// Mark session as completed
  Future<void> markSessionCompleted(String sessionId, {bool success = true}) async {
    try {
      final currentState = await loadSessionState();
      if (currentState?.sessionId == sessionId) {
        final updatedState = SessionState(
          sessionId: currentState!.sessionId,
          learnerId: currentState.learnerId,
          stepId: currentState.stepId,
          itemId: currentState.itemId,
          subject: currentState.subject,
          conversationHistory: currentState.conversationHistory,
          attempts: currentState.attempts,
          lastActive: DateTime.now(),
          completed: true,
        );
        
        await saveSessionState(updatedState);
        
        // Finish session in Firestore
        if (kUseFirebaseAuth) {
          await _firestoreService.finishSession(
            sessionId: sessionId,
            success: success,
            finalAccuracy: success ? 1.0 : 0.0,
          );
        }
        
        // Clear session after short delay to allow UI updates
        Timer(const Duration(seconds: 2), () async {
          await clearSessionState();
        });
      }
    } catch (e) {
      print('SessionPersistenceService: Error marking session completed: $e');
    }
  }

  /// Add message to conversation history
  Future<void> addConversationMessage({
    required String sessionId,
    required String role,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentState = await loadSessionState();
      if (currentState?.sessionId == sessionId) {
        final message = ConversationMessage(
          role: role,
          content: content,
          timestamp: DateTime.now(),
          metadata: metadata,
        );

        final updatedHistory = [...currentState!.conversationHistory, message];
        final updatedState = SessionState(
          sessionId: currentState.sessionId,
          learnerId: currentState.learnerId,
          stepId: currentState.stepId,
          itemId: currentState.itemId,
          subject: currentState.subject,
          conversationHistory: updatedHistory,
          attempts: currentState.attempts,
          lastActive: DateTime.now(),
          completed: currentState.completed,
        );

        await saveSessionState(updatedState);

        // Also save to Firestore conversation history
        if (kUseFirebaseAuth) {
          await _firestoreService.addToConversation(
            sessionId: sessionId,
            role: role,
            message: content,
            metadata: metadata,
          );
        }
      }
    } catch (e) {
      print('SessionPersistenceService: Error adding conversation message: $e');
    }
  }

  /// Update session progress
  Future<void> updateSessionProgress({
    required String sessionId,
    String? newStepId,
    int? attempts,
  }) async {
    try {
      final currentState = await loadSessionState();
      if (currentState?.sessionId == sessionId) {
        final updatedState = SessionState(
          sessionId: currentState!.sessionId,
          learnerId: currentState.learnerId,
          stepId: newStepId ?? currentState.stepId,
          itemId: currentState.itemId,
          subject: currentState.subject,
          conversationHistory: currentState.conversationHistory,
          attempts: attempts ?? currentState.attempts,
          lastActive: DateTime.now(),
          completed: currentState.completed,
        );

        await saveSessionState(updatedState);
      }
    } catch (e) {
      print('SessionPersistenceService: Error updating session progress: $e');
    }
  }

  // Private methods

  Future<void> _saveLocally(SessionState sessionState) async {
    final json = jsonEncode(sessionState.toJson());
    await _prefs?.setString(_sessionKey, json);
  }

  Future<SessionState?> _loadLocally() async {
    final json = _prefs?.getString(_sessionKey);
    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return SessionState.fromJson(data);
      } catch (e) {
        print('SessionPersistenceService: Error parsing local session data: $e');
      }
    }
    return null;
  }

  Future<void> _saveToFirestore(SessionState sessionState) async {
    // Update learner's current session ID
    await _firestoreService.updateLearnerProgress(sessionState.learnerId, {
      'current_session_id': sessionState.sessionId,
    });
  }

  Future<SessionState?> _loadFromFirestore(String learnerId) async {
    try {
      // Get learner data to find current session ID
      final learnerStream = _firestoreService.getLearnerStream(learnerId);
      final learnerData = await learnerStream.first;
      
      if (learnerData == null) return null;
      
      final currentSessionId = learnerData['current_session_id'] as String?;
      if (currentSessionId == null) return null;

      // Get session data
      final sessionStream = _firestoreService.getSessionStream(currentSessionId);
      final sessionData = await sessionStream.first;
      
      if (sessionData == null) return null;

      // Convert Firestore session data to SessionState
      final conversationHistory = (sessionData['conversation_history'] as List? ?? [])
          .map((msg) {
            DateTime timestamp;
            final timestampField = msg['timestamp'];
            if (timestampField is String) {
              timestamp = DateTime.parse(timestampField);
            } else if (timestampField is DateTime) {
              timestamp = timestampField;
            } else {
              timestamp = DateTime.now();
            }
            
            return ConversationMessage(
              role: msg['role'] as String,
              content: msg['message'] as String,
              timestamp: timestamp,
              metadata: msg['metadata'] as Map<String, dynamic>?,
            );
          })
          .toList();

      return SessionState(
        sessionId: currentSessionId,
        learnerId: learnerId,
        stepId: 's${(sessionData['current_step_idx'] ?? 0) + 1}', // Convert index to step ID
        itemId: sessionData['item_id'] as String? ?? '',
        subject: sessionData['subject'] as String? ?? '',
        conversationHistory: conversationHistory,
        attempts: sessionData['attempts_current'] as int? ?? 0,
        lastActive: _parseTimestamp(sessionData['updated_at']),
        completed: sessionData['finished'] as bool? ?? false,
      );
    } catch (e) {
      print('SessionPersistenceService: Error loading from Firestore: $e');
      return null;
    }
  }

  DateTime _parseTimestamp(dynamic timestampField) {
    if (timestampField is String) {
      try {
        return DateTime.parse(timestampField);
      } catch (e) {
        print('SessionPersistenceService: Error parsing timestamp string: $e');
        return DateTime.now();
      }
    } else if (timestampField is DateTime) {
      return timestampField;
    } else {
      return DateTime.now();
    }
  }

  bool _isSessionValid(SessionState sessionState) {
    if (sessionState.completed) return false;
    
    final now = DateTime.now();
    final timeSinceLastActive = now.difference(sessionState.lastActive);
    
    return timeSinceLastActive < _sessionTimeout;
  }

  /// Get session timeout remaining
  Duration? getSessionTimeoutRemaining(SessionState sessionState) {
    if (sessionState.completed) return null;
    
    final now = DateTime.now();
    final timeSinceLastActive = now.difference(sessionState.lastActive);
    final remaining = _sessionTimeout - timeSinceLastActive;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }
}