import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:game_jam/core/config/asset_paths.dart';
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
  right,
  up,
  plain,
}

class WaterComponent extends PositionComponent with HasGameReference<MyGame> {
  final WaterAssetPosition assetPosition;
  WaterComponent({
    required Vector2 position,
    required Vector2 size,
    required this.assetPosition,
  }) : super(position: position, size: size, priority: 20);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (assetPosition != WaterAssetPosition.plain) {
      add(
        WaterSpriteComponent(
          position: Vector2.zero(),
          size: size,
          assetPosition: assetPosition,
        ),
      );
    }
    add(RectangleHitbox(size: size));
  }
}

class WaterSpriteComponent extends SpriteComponent
    with HasGameReference<MyGame> {
  final WaterAssetPosition assetPosition;
  WaterSpriteComponent({
    required Vector2 position,
    required Vector2 size,
    required this.assetPosition,
  }) : super(position: position, size: size, priority: 20);

  @override
  Future<void> onLoad() async {
    sprite = switch (assetPosition) {
      WaterAssetPosition.bottom => Sprite(
        game.images.fromCache(AssetPaths.waterDown),
      ),
      WaterAssetPosition.cornerBottomLeft => Sprite(
        game.images.fromCache(AssetPaths.waterCornerBottomLeft),
      ),
      WaterAssetPosition.cornerBottomRight => Sprite(
        game.images.fromCache(AssetPaths.waterCornerBottomRight),
      ),
      WaterAssetPosition.cornerUpLeft => Sprite(
        game.images.fromCache(AssetPaths.waterCornerTopLeft),
      ),
      WaterAssetPosition.cornerUpRight => Sprite(
        game.images.fromCache(AssetPaths.waterCornerTopRight),
      ),
      WaterAssetPosition.invertedCornerTopLeft => Sprite(
        game.images.fromCache(AssetPaths.waterInvertedCornerTopLeft),
      ),
      WaterAssetPosition.invertedCornerTopRight => Sprite(
        game.images.fromCache(AssetPaths.waterInvertedCornerTopRight),
      ),
      WaterAssetPosition.invertedCornerBottomLeft => Sprite(
        game.images.fromCache(AssetPaths.waterInvertedCornerBottomLeft),
      ),
      WaterAssetPosition.invertedCornerBottomRight => Sprite(
        game.images.fromCache(AssetPaths.waterInvertedCornerBottomRight),
      ),
      WaterAssetPosition.left => Sprite(
        game.images.fromCache(AssetPaths.waterLeft),
      ),
      WaterAssetPosition.right => Sprite(
        game.images.fromCache(AssetPaths.waterRight),
      ),
      WaterAssetPosition.up => Sprite(
        game.images.fromCache(AssetPaths.waterUp),
      ),
      WaterAssetPosition.plain => throw UnimplementedError(),
    };

    return super.onLoad();
  }
}
