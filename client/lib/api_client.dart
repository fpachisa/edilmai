import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config.dart';
import 'auth_service.dart';

class ApiClient {
  final Dio _dio;
  final String base;

  ApiClient(this.base) : _dio = Dio(BaseOptions(baseUrl: base)) {
    // Attach ID token if Firebase auth is enabled and available
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      if (kUseFirebaseAuth) {
        await AuthService.init();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
      return handler.next(options);
    }));
  }

  Future<Map<String, dynamic>> ingestSample() async {
    final data = jsonDecode(_sampleJson) as Map<String, dynamic>;
    final res = await _dio.post('/v1/items/ingest', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startSession({required String learnerId, required String itemId}) async {
    final res = await _dio.post('/v1/session/start', data: {
      'learner_id': learnerId,
      'item_id': itemId,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startAdaptiveSession({required String learnerId, String? itemId}) async {
    final data = {'learner_id': learnerId};
    if (itemId != null) {
      data['item_id'] = itemId;
    }
    final res = await _dio.post('/v1/session/start-adaptive', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startModuleSession({required Map<String, dynamic> sessionData}) async {
    final res = await _dio.post('/v1/session/start-module', data: sessionData);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> continueProgression({required String sessionId}) async {
    final res = await _dio.post('/v1/session/continue-progression', data: {
      'session_id': sessionId,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSession({required String sessionId}) async {
    final res = await _dio.get('/v1/session/$sessionId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProgressionStatus({required String learnerId}) async {
    final res = await _dio.get('/v1/session/progression-status/$learnerId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProfile({required String learnerId}) async {
    final res = await _dio.get('/v1/profile/$learnerId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getItem({required String itemId}) async {
    final res = await _dio.get('/v1/items/$itemId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> ingestJson({required String jsonData}) async {
    final res = await _dio.post('/v1/items/ingest', data: jsonDecode(jsonData));
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> step({
    required String sessionId,
    required String stepId,
    required String userResponse,
  }) async {
    final res = await _dio.post('/v1/session/step', data: {
      'session_id': sessionId,
      'step_id': stepId,
      'user_response': userResponse,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> endSession({required String sessionId}) async {
    final res = await _dio.post('/v1/session/end', data: {'session_id': sessionId});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> whoAmI() async {
    final res = await _dio.get('/whoami');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHomeFeed({required String learnerId}) async {
    final res = await _dio.get('/v1/homefeed/$learnerId');
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listTopics() async {
    final res = await _dio.get('/v1/catalog/topics');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> listCollections() async {
    final res = await _dio.get('/v1/catalog/collections');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> listLearners() async {
    final res = await _dio.get('/v1/parents/learners');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createLearner({required String name, String gradeLevel = 'P6', List<String> subjects = const ['maths']}) async {
    final res = await _dio.post('/v1/parents/learners', data: {
      'name': name,
      'grade_level': gradeLevel,
      'subjects': subjects,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> ensureSampleItem() async {
    try {
      await _dio.get('/v1/items/ALG-S1-E1');
      return;
    } catch (_) {
      // Ingest if missing
      final data = jsonDecode(_sampleJson) as Map<String, dynamic>;
      await _dio.post('/v1/items/ingest', data: data);
    }
  }
}

// Same sample item used by the backend web UI for quick testing.
const String _sampleJson = r'''
{
  "topic": "Algebra",
  "version": "enhanced-v1",
  "items": [
    {
      "id": "ALG-S1-E1",
      "topic": "Algebra",
      "title": "Adding to an Unknown",
      "learn_step": 1,
      "complexity": "Easy",
      "difficulty": 0.25,
      "skill": "Algebraic Expressions",
      "subskills": ["use-variable", "form-addition-expression"],
      "estimated_time_seconds": 30,
      "problem_text": "Amelia has 'b' books. She buys 4 more. Write an expression for how many books she has now.",
      "assets": {"manipulatives": [], "image_url": null, "svg_code": null},
      "student_view": {
        "socratic": true,
        "steps": [
          {
            "id": "s1",
            "prompt": "If Amelia has b books and buys 4 more, what is the new total in terms of b?",
            "hints": [
              {"level": 1, "text": "Start with b and add 4."},
              {"level": 2, "text": "Write it as b + 4."}
            ]
          }
        ],
        "reflect_prompts": ["Why is it addition and not multiplication?"],
        "micro_drills": []
      },
      "teacher_view": {
        "solutions_teacher": ["b + 4"],
        "common_pitfalls": [{"text": "4b instead of b+4", "tag": "concat-for-multiply"}]
      },
      "telemetry": {"scoring": {"xp": 10, "bonus_no_hints": 2}, "prereqs": [], "next_items": []},
      "evaluation": {
        "rules": {
          "regex": [{"equivalent_to": "b+4"}],
          "algebraic_equivalence": true,
          "llm_fallback": true
        },
        "notes": "Regex → CAS → LLM adjudication"
      }
    }
  ]
}
''';
