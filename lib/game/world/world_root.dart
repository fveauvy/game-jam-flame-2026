import 'package:flame/components.dart';
import 'package:game_jam/game/components/player/player_component.dart';

class WorldRoot extends World with HasCollisionDetection {
  PlayerComponent? _player;

  void bindPlayer(PlayerComponent player) {
    _player = player;
  }

  void reset() {
    _player?.reset();
  }
}
