import 'dart:convert';
import 'package:flutter/services.dart';

class AnswerDetails {
  final String correctAnswer;
  final List<String> alternativeAnswers;
  final String answerFormat;

  const AnswerDetails({
    required this.correctAnswer,
    required this.alternativeAnswers,
    required this.answerFormat,
  });

  factory AnswerDetails.fromJson(Map<String, dynamic> json) {
    return AnswerDetails(
      correctAnswer: (json['correct_answer'] ?? '').toString(),
      alternativeAnswers: ((json['alternative_answers'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      answerFormat: (json['answer_format'] ?? 'text').toString(),
    );
  }
}

class AIHint {
  final int step;
  final String hintText;

  const AIHint({
    required this.step,
    required this.hintText,
  });

  factory AIHint.fromJson(Map<String, dynamic> json) {
    return AIHint(
      step: (json['step'] is num) ? (json['step'] as num).toInt() : 1,
      hintText: (json['hint_text'] ?? '').toString(),
    );
  }
}

class AIGuidance {
  final String evaluationStrategy;
  final List<String> keywords;
  final Map<String, String> commonMisconceptions;
  final List<AIHint> hints;
  final String fullSolution;

  const AIGuidance({
    required this.evaluationStrategy,
    required this.keywords,
    required this.commonMisconceptions,
    required this.hints,
    required this.fullSolution,
  });

  factory AIGuidance.fromJson(Map<String, dynamic> json) {
    final hintsData = json['hints'] as List? ?? [];
    final hints = hintsData
        .whereType<Map>()
        .map((h) => AIHint.fromJson(Map<String, dynamic>.from(h)))
        .toList();

    final misconceptions = json['common_misconceptions'] as Map? ?? {};
    final misconceptionsMap = misconceptions.map(
      (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
    );

    return AIGuidance(
      evaluationStrategy: (json['evaluation_strategy'] ?? '').toString(),
      keywords: ((json['keywords'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      commonMisconceptions: misconceptionsMap,
      hints: hints,
      fullSolution: (json['full_solution'] ?? '').toString(),
    );
  }
}

class Problem {
  final String id;
  final String subTopic;
  final String title;
  final String complexity;
  final String problemText;
  final int marks;
  final AnswerDetails answerDetails;
  final AIGuidance aiGuidance;
  final String? imageUrl;
  final String? svgCode;

  const Problem({
    required this.id,
    required this.subTopic,
    required this.title,
    required this.complexity,
    required this.problemText,
    required this.marks,
    required this.answerDetails,
    required this.aiGuidance,
    this.imageUrl,
    this.svgCode,
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    // Parse asset information
    final asset = json['asset'] as Map<String, dynamic>? ?? {};
    
    // Parse answer_details
    final answerDetailsJson = json['answer_details'] as Map<String, dynamic>? ?? {};
    final answerDetails = AnswerDetails.fromJson(answerDetailsJson);
    
    // Parse ai_guidance
    final aiGuidanceJson = json['ai_guidance'] as Map<String, dynamic>? ?? {};
    final aiGuidance = AIGuidance.fromJson(aiGuidanceJson);

    return Problem(
      id: (json['id'] ?? '').toString(),
      subTopic: (json['sub_topic'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      complexity: (json['complexity'] ?? 'Easy').toString(),
      problemText: (json['problem_text'] ?? '').toString(),
      marks: (json['marks'] is num) ? (json['marks'] as num).toInt() : 1,
      answerDetails: answerDetails,
      aiGuidance: aiGuidance,
      imageUrl: asset['image_url']?.toString(),
      svgCode: asset['svg_code']?.toString(),
    );
  }
}

class ProblemLoader {
  static final Map<String, List<Problem>> _cache = {};

  static Future<List<Problem>> loadProblems(String topic) async {
    if (_cache.containsKey(topic)) {
      return _cache[topic]!;
    }

    try {
      final fileName = '${topic.toLowerCase()}.json';
      // Load from Flutter assets folder
      final jsonString = await rootBundle.loadString('assets/$fileName');
      final dynamic parsed = json.decode(jsonString);

      // Coerce to Map<String, dynamic>
      final Map<String, dynamic> jsonData = parsed is Map
          ? Map<String, dynamic>.from(parsed as Map)
          : <String, dynamic>{'questions': parsed};

      // Try new structure first (questions), then fall back to old (items)
      final dynamic rawQuestions = jsonData['questions'] ?? jsonData['items'];
      final List questions = rawQuestions is List ? rawQuestions : const [];
      final problems = questions
          .whereType<Map>()
          .map((item) => Problem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      
      _cache[topic] = problems;
      return problems;
    } catch (e) {
      print('Error loading problems for $topic: $e');
      return [];
    }
  }

  static Future<Problem?> getProblemById(String problemId) async {
    for (final topicProblems in _cache.values) {
      for (final problem in topicProblems) {
        if (problem.id == problemId) {
          return problem;
        }
      }
    }
    
    // Try loading from all topic files if not found
    final topics = ['fractions', 'algebra', 'percentage', 'ratio', 'geometry', 'speed', 'statistics'];
    for (final topic in topics) {
      final problems = await loadProblems(topic);
      for (final problem in problems) {
        if (problem.id == problemId) {
          return problem;
        }
      }
    }
    
    return null;
  }
}
