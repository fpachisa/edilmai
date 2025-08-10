import 'game_state_types.dart';

class _NoopStore implements GameStateStore {
  @override
  Future<GameStateSnapshot?> load() async => null;

  @override
  Future<void> save(GameStateSnapshot snapshot) async {}
}

GameStateStore createStore() => _NoopStore();

