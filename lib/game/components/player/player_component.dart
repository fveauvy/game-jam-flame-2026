import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/game/input/input_state.dart';
import 'package:game_jam/game/my_game.dart';

class PlayerComponent extends RectangleComponent with HasGameReference<MyGame> {
  PlayerComponent({required this.inputState, required Vector2 startPosition})
    : _startPosition = startPosition.clone(),
      super(
        position: startPosition.clone(),
        size: Vector2.all(48),
        anchor: Anchor.topLeft,
        priority: 10,
        paint: Paint()..color = const Color(0xFF2A9D8F),
      );

  final InputState inputState;
  final Vector2 _startPosition;

  double _velocityY = 0;
  bool _onGround = true;

  static const double _moveSpeed = 340;
  static const double _jumpSpeed = -720;
  static const double _gravity = 1800;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.phase.value != GamePhase.playing) {
      return;
    }

    position.x += inputState.moveAxis * _moveSpeed * dt;
    if (inputState.jumpPressed && _onGround) {
      _velocityY = _jumpSpeed;
      _onGround = false;
    }

    _velocityY += _gravity * dt;
    position.y += _velocityY * dt;

    final double maxX = GameConfig.worldSize.x - size.x;
    position.x = position.x.clamp(0, maxX);

    if (position.y >= GameConfig.groundY) {
      position.y = GameConfig.groundY;
      _velocityY = 0;
      _onGround = true;
    }
  }

  void reset() {
    position.setFrom(_startPosition);
    _velocityY = 0;
    _onGround = true;
  }
}
