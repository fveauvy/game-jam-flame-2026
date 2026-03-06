import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/game/my_game.dart';

class WaterComponent extends RectangleComponent
    with HasGameReference<MyGame> {

  WaterComponent({required Vector2 position, required Vector2 size})
      : super(
          position: position,
          size: size,
          priority: 0,
          paint: Paint()..color = Colors.blue,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: size));
  }
}