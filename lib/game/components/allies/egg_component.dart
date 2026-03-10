import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';
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

  void collect() async {
    if (isInSafeHouse) return;
    // Logic for when the player collects the Egg
    game.gameState.savedEggs += 1;
    removeFromParent();
    await FlameAudio.play('sound_effects/whawhawhawhoua.wav');
  }
}
