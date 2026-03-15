import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/game/my_game.dart';

class ThornComponent extends RectangleComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  ThornComponent({
    required Vector2 position,
    required Vector2 size,
    required this.drawLandBackground,
  }) : super(
         position: position,
         size: size,
         priority: 10,
         paint: Paint()..color = Colors.transparent,
       );

  final bool drawLandBackground;
  late List<ui.Image> _thornFrames;
  double _animationElapsed = 0;
  int _animationStep = 0;

  static const List<int> _animationSequence = <int>[0, 1, 2, 1];

  static const Color _landColor = Colors.brown;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _thornFrames = AssetPaths.thornsAnimationCacheKeys
        .map((String key) => Flame.images.fromCache(key))
        .toList(growable: false);
    add(RectangleHitbox(size: size, collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animationElapsed += dt;
    while (_animationElapsed >= GameplayTuning.thornAnimationFrameSeconds) {
      _animationElapsed -= GameplayTuning.thornAnimationFrameSeconds;
      _animationStep = (_animationStep + 1) % _animationSequence.length;
    }
  }

  @override
  void render(Canvas canvas) {
    if (drawLandBackground) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = _landColor,
      );
    }

    _drawRepeatedHorizontally(canvas, width: size.x, height: size.y);
  }

  void _drawRepeatedHorizontally(
    Canvas canvas, {
    required double width,
    required double height,
  }) {
    final ui.Image currentFrame =
        _thornFrames[_animationSequence[_animationStep]];
    final double spriteWidth = currentFrame.width.toDouble();
    final double spriteHeight = currentFrame.height.toDouble();
    final double tileWidth = height * (spriteWidth / spriteHeight);
    double x = 0;

    while (x < width) {
      final double drawWidth = min(tileWidth, width - x);
      canvas.drawImageRect(
        currentFrame,
        Rect.fromLTWH(0, 0, spriteWidth, spriteHeight),
        Rect.fromLTWH(x, 0, drawWidth, height),
        Paint(),
      );

      x += tileWidth;
    }
  }
}
