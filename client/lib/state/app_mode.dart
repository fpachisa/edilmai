import 'package:flutter/foundation.dart';

enum AppMode { learner, parent }

class AppModeController extends ChangeNotifier {
  static final AppModeController instance = AppModeController._();
  AppModeController._();

  AppMode _mode = AppMode.learner;
  AppMode get mode => _mode;

  bool get isLearner => _mode == AppMode.learner;
  bool get isParent => _mode == AppMode.parent;

  void switchTo(AppMode next) {
    if (_mode == next) return;
    _mode = next;
    notifyListeners();
  }

  void toggle() {
    switchTo(_mode == AppMode.learner ? AppMode.parent : AppMode.learner);
  }
}

