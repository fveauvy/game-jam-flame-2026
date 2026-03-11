import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/components/environment/fly_component.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/my_game.dart';

class FishEnemyComponent extends SpriteAnimationComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  Vector2 initialPosition;
  Vector2 initialSize;

  bool isEating = false;
  FishEnemyComponent({required this.initialPosition, required this.initialSize})
    : super(
        priority: 0,
        size: initialSize,
        position: initialPosition,
        autoResize: false,
        paint: Paint()..blendMode = BlendMode.screen,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = idleAnimation;
    add(CircleHitbox());
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is FlyComponent) {
      eat(other);
    }
    if (other is PlayerComponent) {
      eat(other);
    }
  }

  void eat(PositionComponent other) {
    isEating = true;
    animation = eatAnimation;
    paint.blendMode = BlendMode.srcOver;
    Future.delayed(Duration(milliseconds: (deathTimeInS * 1000).toInt()), () {
      other.removeFromParent();
    });
    Future.delayed(
      Duration(milliseconds: (animationsTimeInS * 1000).toInt()),
      () {
        animation = idleAnimation;
        isEating = false;
        paint.blendMode = BlendMode.screen;
      },
    );
  }

  /// Animations

  static const int totalFrames = 43;
  static const int closingMouthFrame = 12;

  static const double _stepTimeInS = 3 / totalFrames;

  static const double animationsTimeInS = _stepTimeInS * totalFrames;
  static const double deathTimeInS = closingMouthFrame / totalFrames;

  List<Sprite> get spriteList =>
      List<Sprite>.generate(AssetPaths.croqueAnimationFrames, (index) {
        final frameNumber = index;
        return Sprite(
          game.images.fromCache(
            '${AssetPaths.croqueAnimationPrefix}$frameNumber.png',
          ),
        );
      });
  SpriteAnimation get idleAnimation =>
      SpriteAnimation.spriteList([spriteList[19]], stepTime: _stepTimeInS);

  SpriteAnimation get eatAnimation => SpriteAnimation.variableSpriteList(
    [
      19,
      18,
      17,
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
    ].map((i) => spriteList[i]).toList(),

    stepTimes: [
      3,
      2,
      3,
      4,
      4,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      3,
      2,
      2,
      2,
      1,
      2,
      2,
      3,
    ].map((frame) => frame * _stepTimeInS).toList(),
    loop: false,
  );
}
