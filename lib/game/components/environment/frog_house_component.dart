import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/game/components/allies/egg_component.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/my_game.dart';

class FrogHouseComponent extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  FrogHouseComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, priority: 0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final hitbox = RectangleHitbox(
      size: size,
      position: Vector2.zero(),
      priority: 0,
      collisionType: CollisionType.passive,
    );
    add(hitbox);
    sprite = Sprite(game.images.fromCache(AssetPaths.plankPanel1CacheKey));
  }

  @override
  void update(double dt) {
    final savedEggs = children
        .whereType<EggComponent>()
        .where((egg) => egg.isInSafeHouse)
        .length;
    if (savedEggs >= GameplayTuning.initialEggCount) {
      game.winGame();
    }
    super.update(dt);
  }

  static const double _eggCellSize = 40;

  @override
  Future<void> onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) async {
    if (other is PlayerComponent) {
      final maxRow = (size.y / _eggCellSize).floor().clamp(1, 999);
      final maxEggsPerRow = ((size.x) / _eggCellSize).floor().clamp(1, 999);
      final existingCount = children
          .whereType<EggComponent>()
          .where((egg) => egg.isInSafeHouse)
          .length;
      final targetSavedEggs = game.gameState.savedEggs.clamp(
        0,
        GameplayTuning.initialEggCount,
      );
      final eggsToAdd = targetSavedEggs - existingCount;
      other.eggsCollected = 0;
      other.removeWhere((child) => child is EggComponent);

      for (var i = 0; i < eggsToAdd; i++) {
        final index = existingCount + i;
        final col = index % maxEggsPerRow;
        final row = (index ~/ maxEggsPerRow) % maxRow;
        final x = col * _eggCellSize;
        final y = size.y - (row + 1) * _eggCellSize;

        final egg = EggComponent(
          isInSafeHouse: true,
          size: Vector2.all(_eggCellSize),
          position: Vector2(x, y),
        );
        add(egg);
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
