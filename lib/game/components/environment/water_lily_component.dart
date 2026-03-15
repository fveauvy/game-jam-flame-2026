import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/my_game.dart';

class WaterLilyComponent extends SpriteComponent with HasGameReference<MyGame> {
  WaterLilyComponent({required Vector2 position, required this.radius})
    : super(position: position, priority: 100, size: Vector2.all(radius * 2));

  final double radius;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = Sprite(game.images.fromCache(AssetPaths.waterLilyCacheKey));
    add(CircleHitbox(radius: radius, collisionType: CollisionType.passive));
  }
}
