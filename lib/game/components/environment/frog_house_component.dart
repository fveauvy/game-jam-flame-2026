import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/my_game.dart';

class FrogHouseComponent extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  FrogHouseComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: size));
    sprite = Sprite(game.images.fromCache(AssetPaths.plankPanel1CacheKey));
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is PlayerComponent) {}
    super.onCollisionStart(intersectionPoints, other);
  }
}
