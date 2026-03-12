import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/components/utils/vision_hit_box.dart';
import 'package:game_jam/game/my_game.dart';
import 'package:game_jam/game/utils/position_component_extension.dart';

class SimpleOpponent extends CircleComponent
    with HasGameReference<MyGame>, CollisionCallbacks
    implements VisionHitBoxDelegate {
  PositionComponent? _target;

  SimpleOpponent({
    required Vector2 position,
    required double radius,
    double speed = 120,
  }) : _speed = speed,
       super(
         position: position,
         radius: radius,
         priority: 100,
         paint: Paint()..color = Colors.red,
       );

  double _speed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final visionRadius = radius * 4;
    add(CircleHitbox(radius: radius));

    add(
      VisionHitBox(
        radius: visionRadius,
        position: -Vector2.all(visionRadius - radius),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.phase.value != GamePhase.playing) {
      return;
    }
    final target = _target;
    if (target == null) return;
    followComponent(_speed, dt, target);
  }

  @override
  void onVisionHitBoxCollisionEnd(PositionComponent other) {
    _target = null;
    _speed = 120;
  }

  @override
  void onVisionHitBoxCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (_target != null) return;
    if (other is PlayerComponent) {
      _target = other;
      _speed = other.moveSpeed * 1.5;
    }
  }
}
