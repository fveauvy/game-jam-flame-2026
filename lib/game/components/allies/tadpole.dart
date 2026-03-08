import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:game_jam/game/my_game.dart';

class Egg extends SpriteComponent with HasGameReference<MyGame> {
  Egg({required super.position, super.size})
    : super(sprite: Sprite(Flame.images.fromCache('eggs.png')));

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: size.x));
  }

  void collect() async {
    // Logic for when the player collects the Egg
    game.gameState.savedEggs += 1;
    removeFromParent();
    await FlameAudio.play('sound_effects/whawhawhawhoua.wav');
  }
}
