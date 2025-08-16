import 'package:flutter/foundation.dart';

class ActiveLearner extends ChangeNotifier {
  static final ActiveLearner instance = ActiveLearner._();
  ActiveLearner._();

  String? _learnerId;
  String? _name;

  String? get id => _learnerId;
  String get name => _name ?? 'Your Learner';

  void setActive({required String id, required String name}) {
    _learnerId = id;
    _name = name.isNotEmpty ? name : 'Your Learner';
    notifyListeners();
  }
}

