import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/post_process.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/game/components/allies/egg_post_process.dart';
import 'package:game_jam/game/my_game.dart';

class EggComponent extends PositionComponent with HasGameReference<MyGame> {
  final bool isInSafeHouse;

  /// remove colision hitbox if true, used for the egg onThe frog's back
  final bool isOnBack;

  /// Extra padding (in game units) around the sprite given to the
  /// [PostProcessComponent] so the glow halo has room to render.
  static const double padding = 12.0;

  EggComponent({
    required super.position,
    super.size,
    required this.isInSafeHouse,
    this.isOnBack = false,
  });

  @override
  Future<void> onLoad() async {
    anchor = isOnBack ? Anchor.center : Anchor.topLeft;
    final spriteChild = SpriteComponent(
      sprite: Sprite(Flame.images.fromCache(AssetPaths.bigEggCacheKey)),
      size: size,
      anchor: Anchor.topLeft,
    );

    if (isOnBack) {
      add(spriteChild);
    } else {
      // Wrap the sprite in a PostProcessComponent so the animation shader has
      add(
        PostProcessComponent<EggAnimationProcess>(
          postProcess: EggAnimationProcess(),
          position: Vector2.all(-padding),
          size: size + Vector2.all(padding * 2),
          children: [
            // Offset the sprite so it is centred inside the larger canvas.
            SpriteComponent(
              sprite: Sprite(Flame.images.fromCache(AssetPaths.bigEggCacheKey)),
              position: size + Vector2.all(padding / 2),
              size: size * 1.25,
              anchor: Anchor.topLeft,
            ),
          ],
        ),
      );
      add(
        CircleHitbox(radius: size.x / 2, collisionType: CollisionType.passive),
      );
    }
  }

  Future<void> collect() async {
    if (isOnBack) return;
    if (isInSafeHouse) return;
    game.gameState.savedEggs = (game.gameState.savedEggs + 1).clamp(
      0,
      GameplayTuning.initialEggCount,
    );
    removeFromParent();
    await game.playSfx(AssetPaths.splashAudioEffect);
  }
}
