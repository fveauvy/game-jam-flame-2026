
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/game/my_game.dart';

class WaterLilyComponent extends CircleComponent with HasGameReference<MyGame> {
  WaterLilyComponent({required Vector2 position, required double radius})
      : super(
          position: position,
          radius: radius,
          priority: 100,
          paint: Paint()..color = Colors.green,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: radius));
  }
}