import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/my_game.dart';

class EggComponent extends SpriteComponent with HasGameReference<MyGame> {
  final bool isInSafeHouse;

  EggComponent({
    required super.position,
    super.size,
    required this.isInSafeHouse,
  }) : super(sprite: Sprite(Flame.images.fromCache('eggs.png')));

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: size.x / 2));
  }

  Future<void> collect() async {
    if (isInSafeHouse) return;
    game.gameState.savedEggs += 1;
    removeFromParent();
    await game.playSfx(AssetPaths.splashAudioEffect);
  }
}
