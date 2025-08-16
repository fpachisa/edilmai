import 'dart:convert';
import 'package:flutter/services.dart';

class LearningPathModule {
  final String id;
  final String title;

  const LearningPathModule({
    required this.id,
    required this.title,
  });

  factory LearningPathModule.fromJson(Map<String, dynamic> json) {
    return LearningPathModule(
      id: json['id'],
      title: json['title'],
    );
  }
}

class LearningPath {
  final String title;
  final List<LearningPathModule> modules;

  const LearningPath({
    required this.title,
    required this.modules,
  });

  factory LearningPath.fromJson(Map<String, dynamic> json) {
    return LearningPath(
      title: json['title'],
      modules: (json['modules'] as List)
          .map((moduleJson) => LearningPathModule.fromJson(moduleJson))
          .toList(),
    );
  }
}

class LearningPathLoader {
  static final Map<String, LearningPath> _cache = {};

  static Future<LearningPath?> loadPath(String pathId) async {
    // Return from cache if already loaded
    if (_cache.containsKey(pathId)) {
      return _cache[pathId];
    }

    try {
      // Load from centralized topics file
      final jsonString = await rootBundle.loadString('assets/p6_maths_topics.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final subjects = jsonData['subjects'] as List;
      
      // Find the subject that matches the pathId
      for (final subject in subjects) {
        if (subject['id'] == pathId) {
          // Convert centralized format to LearningPath format
          final modules = <LearningPathModule>[];
          
          for (final subtopic in subject['subtopics']) {
            // Create a module for each subtopic
            modules.add(LearningPathModule(
              id: subtopic['id'],
              title: subtopic['display_name'],
            ));
          }
          
          final path = LearningPath(
            title: subject['display_name'],
            modules: modules,
          );
          
          _cache[pathId] = path;
          return path;
        }
      }
    } catch (e) {
      print('Error loading learning path $pathId: $e');
    }
    
    return null;
  }

  static Future<List<String>> getAvailablePaths() async {
    try {
      final jsonString = await rootBundle.loadString('assets/p6_maths_topics.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final subjects = jsonData['subjects'] as List;
      return subjects.map<String>((subject) => subject['id']).toList();
    } catch (e) {
      print('Error loading available paths: $e');
      return [];
    }
  }

  static Future<Map<String, LearningPath>> loadAllPaths() async {
    final availablePaths = await getAvailablePaths();
    final Map<String, LearningPath> paths = {};
    
    for (final pathId in availablePaths) {
      final path = await loadPath(pathId);
      if (path != null) {
        paths[pathId] = path;
      }
    }
    
    return paths;
  }
}

// All modules are unlocked - no prerequisites
bool isModuleUnlocked(LearningPathModule module, Map<String, double> progress) {
  return true;
}

// Helper function to get next unlocked module
LearningPathModule? getNextModule(List<LearningPathModule> modules, Map<String, double> progress) {
  for (final module in modules) {
    final moduleProgress = progress[module.id] ?? 0.0;
    final isUnlocked = isModuleUnlocked(module, progress);
    
    if (isUnlocked && moduleProgress < 0.8) {
      return module; // Found next module to work on
    }
  }
  return null; // All completed
}