import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
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
         priority: 1,
         paint: Paint()..color = Colors.transparent,
       );

  final bool drawLandBackground;
  late ui.Image _thornImage;

  static const Color _landColor = Colors.brown;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _thornImage = Flame.images.fromCache(AssetPaths.thornsCacheKey);
    add(RectangleHitbox(size: size));
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
    final double spriteWidth = _thornImage.width.toDouble();
    final double spriteHeight = _thornImage.height.toDouble();
    final double tileWidth = height * (spriteWidth / spriteHeight);
    double x = 0;

    while (x < width) {
      final double drawWidth = min(tileWidth, width - x);
      canvas.drawImageRect(
        _thornImage,
        Rect.fromLTWH(0, 0, spriteWidth, spriteHeight),
        Rect.fromLTWH(x, 0, drawWidth, height),
        Paint(),
      );

      x += tileWidth;
    }
  }
}
