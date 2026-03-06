import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/game/input/input_state.dart';
import 'package:game_jam/game/my_game.dart';

class PlayerComponent extends CircleComponent with HasGameReference<MyGame> {
  final String name;
  final Color color;

  PlayerComponent({required this.inputState, required Vector2 startPosition, required this.name, this.color = const Color(0xFF2A9D8F)})
    : _startPosition = startPosition.clone(),
      super(
        position: startPosition.clone(),
        radius: 48,
        anchor: Anchor.topLeft,
        priority: 10,
        paint: Paint()..color = color,
      );

  final InputState inputState;
  final Vector2 _startPosition;


  static const double _moveSpeed = 340;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.phase.value != GamePhase.playing) {
      return;
    }

    position.x += inputState.moveAxisX * _moveSpeed * dt;
    position.y += inputState.moveAxisY * _moveSpeed * dt;

    

    final double maxX = GameConfig.worldSize.x - size.x;
    position.x = position.x.clamp(0, maxX);

  }

  void reset() {
    position.setFrom(_startPosition);
  }
}
