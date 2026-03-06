import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/game/input/input_state.dart';
import 'package:game_jam/game/my_game.dart';

class PlayerComponent extends CircleComponent with HasGameReference<MyGame> {
  final String name;
  final Color color;

  final double speedMultiplier;
  final double sizeMultiplier;

  // 0 to 2, how smart the player is (0 dummy, 1 normal, 2 super smart ) 
  final double intelligence;

  PlayerComponent({
    required this.inputState,
    required Vector2 startPosition,
    required this.name,
    this.color = const Color(0xFF2A9D8F),
    this.speedMultiplier = 1.0,
    this.sizeMultiplier = 1.0,
    this.intelligence = 1.0,
  }) : _startPosition = startPosition.clone(),
       super(
         position: startPosition.clone(),
         radius: 48 * sizeMultiplier,
         anchor: Anchor.center,
         priority: 10,
         paint: Paint()..color = color,
       );

  final InputState inputState;
  final Vector2 _startPosition;

  static const double _moveSpeed = 340;
  static const double _rotationSpeed = 30;

  late Paint _directionDotPaint;

  @override
  void onMount() {
    super.onMount();
    _directionDotPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw 2 direction dots at the top of the circle
    final dotRadius = radius * 0.15 * intelligence;
    final dotOffset = radius * 0.5;
    final topY = dotRadius;

    // Left dot
    canvas.drawCircle(
      Offset(dotOffset, topY),
      dotRadius,
      _directionDotPaint,
    );

    // Right dot
    canvas.drawCircle(
      Offset(dotOffset + radius, topY),
      dotRadius,
      _directionDotPaint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.phase.value != GamePhase.playing) {
      return;
    }

    // Create velocity vector from input axes
    final Vector2 velocity = Vector2(
      inputState.moveAxisX,
      inputState.moveAxisY,
    );

    position += velocity * _moveSpeed * speedMultiplier * dt;

    /// smooth rotate toward movement direction
    final targetAngle = velocity.screenAngle();

    if (targetAngle != angle && (velocity.x != 0 || velocity.y != 0)) {
      //determine if we should rotate clockwise or counterclockwise
      //TODO: this is not the right thing for every cases
      final double angleNeeded = targetAngle - angle;
      final bool clockwise = angleNeeded > 0;
      if (clockwise) {
        angle += min(angleNeeded, _rotationSpeed * speedMultiplier * dt);
      } else {
        angle -= min(-angleNeeded, _rotationSpeed * speedMultiplier * dt);
      }
    }

    final double maxX = GameConfig.worldSize.x - size.x;
    final double maxY = GameConfig.worldSize.y - size.y;
    position.y = position.y.clamp(0, maxY);
    position.x = position.x.clamp(0, maxX);
  }

  void reset() {
    position.setFrom(_startPosition);
  }
}
