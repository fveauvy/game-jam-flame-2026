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
  left,
  plain,
  right,
  up,
}

class WaterComponent extends SpriteComponent with HasGameReference<MyGame> {
  final WaterAssetPosition assetPosition;
  WaterComponent({
    required Vector2 position,
    required Vector2 size,
    required this.assetPosition,
  }) : super(position: position, size: size, priority: 0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = Sprite(
      game.images.fromCache(assetPath),
      srcSize: Vector2(100, 100),
    );
    add(
      RectangleHitbox(
        size: size,
        priority: 1,
        collisionType: CollisionType.passive,
      ),
    );
  }

  String get assetPath => switch (assetPosition) {
    WaterAssetPosition.bottom => AssetPaths.waterBottom,
    WaterAssetPosition.cornerBottomLeft => AssetPaths.waterCornerBottomLeft,
    WaterAssetPosition.cornerBottomRight => AssetPaths.waterCornerBottomRight,
    WaterAssetPosition.cornerUpLeft => AssetPaths.waterCornerUpLeft,
    WaterAssetPosition.cornerUpRight => AssetPaths.waterCornerUpRight,
    WaterAssetPosition.left => AssetPaths.waterLeft,
    WaterAssetPosition.plain => AssetPaths.waterPlain,
    WaterAssetPosition.right => AssetPaths.waterRight,
    WaterAssetPosition.up => AssetPaths.waterUp,
  };
}
