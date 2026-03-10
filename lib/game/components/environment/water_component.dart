import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/my_game.dart';

class WaterComponent extends SpriteComponent with HasGameReference<MyGame> {
  WaterComponent({required Vector2 position, required Vector2 size})
    : super(
        position: position,
        size: size,
        priority: 0,
        sprite: Sprite(
          Flame.images.fromCache(AssetPaths.waterTexture),
          srcSize: Vector2(100, 100),
        ),
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: size, priority: 1));
  }
}
