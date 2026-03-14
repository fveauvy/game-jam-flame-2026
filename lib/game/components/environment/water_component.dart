import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/game/my_game.dart';

enum WaterAssetPosition {
  bottom,
  cornerBottomLeft,
  cornerBottomRight,
  cornerUpLeft,
  cornerUpRight,
  invertedCornerTopLeft,
  invertedCornerTopRight,
  invertedCornerBottomLeft,
  invertedCornerBottomRight,
  left,
  plain,
  right,
  up,
}

class WaterComponent extends RectangleComponent with HasGameReference<MyGame> {
  final WaterAssetPosition assetPosition;
  WaterComponent({
    required Vector2 position,
    required Vector2 size,
    required this.assetPosition,
  }) : super(position: position, size: size, priority: 0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    paint = Paint()..color = const Color.fromARGB(255, 151, 200, 186);
  }
}

class WaterSpriteComponent extends SpriteComponent
    with HasGameReference<MyGame> {
  final WaterAssetPosition assetPosition;
  WaterSpriteComponent({
    required Vector2 position,
    required Vector2 size,
    required this.assetPosition,
  }) : super(position: position, size: size, priority: 0);

  @override
  Future<void> onLoad() async {
    // sprite = Sprite(
    // game.images.fromCache(assetPath),
    // srcSize: Vector2(100, 100),
    // );
    return super.onLoad();
  }

  // String get assetPath => switch (assetPosition) {
  //   WaterAssetPosition.bottom => AssetPaths.waterBottom,
  //   WaterAssetPosition.invertedCornerBottomRight =>
  //     AssetPaths.waterInvertedCornerBottomLeft,
  //   WaterAssetPosition.invertedCornerBottomLeft =>
  //     AssetPaths.waterInvertedCornerBottomRight,
  //   WaterAssetPosition.invertedCornerTopLeft =>
  //     AssetPaths.waterInvertedCornerTopLeft,
  //   WaterAssetPosition.invertedCornerTopRight =>
  //     AssetPaths.waterInvertedCornerTopRight,
  //   WaterAssetPosition.left => AssetPaths.waterLeft,
  //   WaterAssetPosition.plain =>
  //     AssetPaths.waterPlainAnimationCacheKeys[Random().nextInt(
  //       AssetPaths.waterPlainAnimationCacheKeys.length,
  //     )],
  //   WaterAssetPosition.right => AssetPaths.waterRight,
  //   WaterAssetPosition.up => AssetPaths.waterUp,
  //   WaterAssetPosition.cornerBottomRight => AssetPaths.waterCornerBottomRight,
  //   WaterAssetPosition.cornerUpLeft => AssetPaths.waterCornerUpLeft,
  //   WaterAssetPosition.cornerUpRight => AssetPaths.waterCornerUpRight,
  //   WaterAssetPosition.cornerBottomLeft => AssetPaths.waterCornerBottomLeft,
  // };
}
