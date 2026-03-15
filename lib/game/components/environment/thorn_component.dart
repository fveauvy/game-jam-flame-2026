import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/my_game.dart';

class ThornComponent extends SpriteAnimationComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  ThornComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, priority: 10);

  static const List<int> _animationSequence = <int>[0, 1, 2, 1];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final List<Sprite> animations = AssetPaths.thornsAnimationCacheKeys
        .map(
          (String key) =>
              Sprite(Flame.images.fromCache(key), srcSize: Vector2(535, 535)),
        )
        .toList();

    animation = SpriteAnimation.variableSpriteList(
      _animationSequence.map((index) => animations[index]).toList(),
      stepTimes: _animationSequence.map((index) => 0.2).toList(),
    );
    add(RectangleHitbox(size: size, collisionType: CollisionType.passive));
  }
}
