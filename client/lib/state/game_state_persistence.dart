import 'game_state_types.dart';
import 'game_state_store_stub.dart' if (dart.library.html) 'game_state_store_web.dart';

export 'game_state_types.dart';

GameStateStore createDefaultGameStateStore() => createStore();

