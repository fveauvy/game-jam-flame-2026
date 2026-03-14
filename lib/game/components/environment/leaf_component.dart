import 'package:flame/components.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/my_game.dart';

class LeafComponent extends SpriteComponent with HasGameReference<MyGame> {
  LeafComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, priority: 2);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = Sprite(game.images.fromCache(AssetPaths.leafCacheKey));
  }
}
