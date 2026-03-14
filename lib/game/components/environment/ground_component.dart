import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/my_game.dart';

class GroundComponent extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  int get damage => 1;
  int get damageInterval => 1;

  GroundComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, priority: 0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = Sprite(
      game.images.fromCache(
        AssetPaths.groundAnimationCacheKeys.elementAt(
          game.random.nextInt(AssetPaths.groundAnimationCacheKeys.length),
        ),
      ),
    );
    add(RectangleHitbox(size: size, collisionType: CollisionType.passive));
  }
}
