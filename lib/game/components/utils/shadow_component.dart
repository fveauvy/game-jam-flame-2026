import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/game/my_game.dart';

class ShadowComponent extends CircleComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  ShadowComponent({required Vector2 position, required double radius})
    : super(
        position: position,
        radius: radius,
        paint: Paint()..color = Colors.black.withValues(alpha: 0.5),
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }
}
