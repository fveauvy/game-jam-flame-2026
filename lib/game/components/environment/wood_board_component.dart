import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/my_game.dart';

class WoodBoardComponent extends SpriteComponent with HasGameReference<MyGame> {
  WoodBoardComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = Sprite(game.images.fromCache(AssetPaths.plankPanel1CacheKey));
    add(RectangleHitbox(size: size));
  }
}
