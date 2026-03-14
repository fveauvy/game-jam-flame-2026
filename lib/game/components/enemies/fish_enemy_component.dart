import 'dart:async';
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
  PositionComponent? target;
  bool isEating = false;
  double timeSinceStartingEat = 0;
  late final List<Sprite> _sprites;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _eatAnimation;

  FishEnemyComponent({required this.initialPosition, required this.initialSize})
    : super(
        priority: 2,
        size: initialSize,
        position: initialPosition,
        autoResize: false,
        anchor: Anchor.center,
        paint: Paint()..blendMode = BlendMode.screen,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprites = List<Sprite>.generate(AssetPaths.croqueAnimationFrames, (index) {
      final int frameNumber = index;
      return Sprite(
        game.images.fromCache(
          '${AssetPaths.croqueAnimationPrefix}$frameNumber.png',
        ),
      );
    }, growable: false);
    _idleAnimation = SpriteAnimation.spriteList([
      _sprites[19],
    ], stepTime: _stepTimeInS);
    _eatAnimation = SpriteAnimation.variableSpriteList(
      <int>[
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
      ].map((i) => _sprites[i]).toList(growable: false),
      stepTimes: <int>[
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
      ].map((frame) => frame * _stepTimeInS).toList(growable: false),
      loop: false,
    );
    animation = _idleAnimation;
    add(
      CircleHitbox(
        radius: (initialSize.x / 3),
        position: Vector2(initialSize.x / 2, initialSize.y / 2),
        anchor: Anchor.center,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isEating && timeSinceStartingEat != 0) {
      timeSinceStartingEat = 0;
    }
    if (isEating) {
      timeSinceStartingEat += dt;
    }
    if (timeSinceStartingEat >= deathTimeInS &&
        target != null &&
        timeSinceStartingEat <= deathTimeInS + 0.6) {
      if (target is PlayerComponent) {
        unawaited(
          (target as PlayerComponent).applyDamageWithInvincibilityDelay(
            50,
            1.0,
          ),
        );
      } else {
        target?.removeFromParent();
      }
      target = null;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (game.phase.value != GamePhase.playing) return;
    if (other is FlyComponent || other is PlayerComponent) {
      startEating();
      target = other;
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other == target) {
      target = null;
    }
  }

  void startEating() async {
    if (isEating) return;
    isEating = true;
    animation = _eatAnimation;
    paint.blendMode = BlendMode.srcOver;
    await Future.delayed(
      Duration(milliseconds: (animationsTimeInS * 1000).toInt()),
      () {
        animation = _idleAnimation;
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
  static const double deathTimeInS = closingMouthFrame * _stepTimeInS;
}
