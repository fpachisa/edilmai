import 'dart:convert';
import 'dart:html' as html;
import 'game_state_types.dart';

class WebLocalStorageStore implements GameStateStore {
  static const _key = 'psle_game_state_v1';

  @override
  Future<GameStateSnapshot?> load() async {
    try {
      final raw = html.window.localStorage[_key];
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return GameStateSnapshot.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(GameStateSnapshot snapshot) async {
    try {
      html.window.localStorage[_key] = jsonEncode(snapshot.toJson());
    } catch (_) {
      // ignore failures in web local storage
    }
  }
}

GameStateStore createStore() => WebLocalStorageStore();

