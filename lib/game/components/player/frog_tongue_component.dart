import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/game/components/environment/fly_component.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/my_game.dart';

class FrogTongueComponent extends SpriteAnimationComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  FrogTongueComponent({required this.player})
    : super(
        size: Vector2(GameplayTuning.tongueWidth, GameplayTuning.tongueHeight),
        anchor: Anchor.bottomCenter,
        priority: 130,
      );

  final PlayerComponent player;

  late final RectangleHitbox _hitbox = RectangleHitbox(
    size: Vector2(
      size.x * GameplayTuning.tongueHitboxWidthFactor,
      size.y * GameplayTuning.tongueHitboxHeightFactor,
    ),
    position: Vector2(
      size.x * (1 - GameplayTuning.tongueHitboxWidthFactor) / 2,
      size.y * (1 - GameplayTuning.tongueHitboxHeightFactor),
    ),
    anchor: Anchor.topLeft,
    collisionType: CollisionType.inactive,
  );

  late final SpriteAnimation _lickAnimation = SpriteAnimation.spriteList(
    <Sprite>[
      Sprite(game.images.fromCache(AssetPaths.tongue1CacheKey)),
      Sprite(game.images.fromCache(AssetPaths.tongue2CacheKey)),
      Sprite(game.images.fromCache(AssetPaths.tongue3CacheKey)),
    ],
    stepTime: GameplayTuning.tongueAnimationStepSeconds,
    loop: false,
  );

  double _cooldownRemaining = 0;
  double _activeRemaining = 0;

  bool tryLick() {
    if (_cooldownRemaining > 0 || _activeRemaining > 0) {
      return false;
    }
    _cooldownRemaining = GameplayTuning.tongueCooldownSeconds;
    _activeRemaining = GameplayTuning.tongueActiveSeconds;
    animation = _lickAnimation;
    animationTicker?.reset();
    _hitbox.collisionType = CollisionType.active;
    return true;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = null;
    await add(_hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _cooldownRemaining = (_cooldownRemaining - dt).clamp(
      0.0,
      GameplayTuning.tongueCooldownSeconds,
    );

    final Vector2 forward = Vector2(sin(player.angle), -cos(player.angle));
    final double mouthOffset =
        (player.size.x * GameplayTuning.tongueMouthOffsetFactor) +
        GameplayTuning.tongueMouthOffsetPixels;
    position.setFrom(player.absoluteCenter + (forward * mouthOffset));
    angle = player.angle;

    if (_activeRemaining <= 0) {
      return;
    }

    _activeRemaining = (_activeRemaining - dt).clamp(
      0.0,
      GameplayTuning.tongueActiveSeconds,
    );

    if (_activeRemaining > 0) {
      return;
    }

    animation = null;
    _hitbox.collisionType = CollisionType.inactive;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (_activeRemaining > 0 && other is FlyComponent) {
      player.onFlyCaughtFromTongue(other);
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
