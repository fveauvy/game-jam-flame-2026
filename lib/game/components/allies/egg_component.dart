import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/my_game.dart';

class EggComponent extends SpriteComponent with HasGameReference<MyGame> {
  final bool isInSafeHouse;

  /// remove colision hitbox if true, used for the egg onThe frog's back
  final bool isOnBack;

  EggComponent({
    required super.position,
    super.size,
    required this.isInSafeHouse,

    this.isOnBack = false,
  }) : super(
         sprite: Sprite(Flame.images.fromCache('eggs.png')),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    if (!isOnBack) {
      add(CircleHitbox(radius: size.x / 2));
    }
  }

  Future<void> collect() async {
    if (isOnBack) return;
    if (isInSafeHouse) return;
    game.gameState.savedEggs += 1;
    removeFromParent();
    await game.playSfx(AssetPaths.splashAudioEffect);
  }
}
