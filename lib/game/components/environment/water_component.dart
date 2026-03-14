import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:game_jam/game/my_game.dart';

class WaterComponent extends PositionComponent with HasGameReference<MyGame> {
  WaterComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, priority: 0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      RectangleHitbox(
        size: size,
        priority: 1,
        collisionType: CollisionType.passive,
      ),
    );
  }
}
