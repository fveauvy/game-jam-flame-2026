import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/physics_tuning.dart';
import 'package:game_jam/game/components/enemies/bird/bird_component.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/my_game.dart';

enum ShadowType { max, min, normal }

class BirdShadowComponent extends SpriteAnimationGroupComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  BirdShadowComponent({super.position, required super.size})
    : super(priority: 10);

  late final SpriteAnimationGroupComponent _animations;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    final sequence = [1, 2, 1, 1, 2, 1, 1, 1, 2, 1, 2];
    _animations = SpriteAnimationGroupComponent(
      animations: {
        ShadowType.min: SpriteAnimation.variableSpriteList(
          sequence
              .map(
                (index) => Sprite(
                  game.images.fromCache(
                    AssetPaths.birdShadowAnimatedSpriteCacheKey(index),
                  ),
                  srcSize: Vector2(1073, 536),
                ),
              )
              .toList(),
          stepTimes: sequence.map((index) => 0.3).toList(),
        ),
        ShadowType.normal: SpriteAnimation.variableSpriteList(
          sequence
              .map(
                (index) => Sprite(
                  game.images.fromCache(
                    AssetPaths.birdFloutixAnimatedSpriteCacheKey(index),
                  ),
                  srcSize: Vector2(1073, 536),
                ),
              )
              .toList(),
          stepTimes: sequence.map((index) => 0.3).toList(),
        ),
        ShadowType.max: SpriteAnimation.variableSpriteList(
          sequence
              .map(
                (index) => Sprite(
                  game.images.fromCache(
                    AssetPaths.birdFloutixMaxAnimatedSpriteCacheKey(index),
                  ),
                  srcSize: Vector2(1073, 536),
                ),
              )
              .toList(),
          stepTimes: sequence.map((index) => 0.3).toList(),
        ),
      },
    );
    _animations.size = size;
    _animations.current = ShadowType.max;
    _animations.paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..blendMode = BlendMode.multiply;

    add(_animations);
    await super.onLoad();
  }

  @override
  void update(double dt) {
    final PlayerComponent? player = game.world.player;
    if (player == null || game.paused) {
      super.update(dt);
      return;
    }
    final distanceToPlayer = (parent as PositionComponent).position.distanceTo(
      player.position,
    );
    if (distanceToPlayer > PhysicsTuning.birdShadowMaxTypeDistance) {
      _animations.current = ShadowType.max;
    } else if (distanceToPlayer > PhysicsTuning.birdShadowNormalTypeDistance) {
      _animations.current = ShadowType.normal;
    } else {
      _animations.current = ShadowType.min;
    }
    if (distanceToPlayer < PhysicsTuning.birdShadowAttackTriggerDistance) {
      (parent as BirdComponent).startAttack();
    }

    _updateAlphaByDistance(distanceToPlayer, dt);

    if (distanceToPlayer < PhysicsTuning.birdShadowFadeInStartDistance) {
      _scaleToParentSize(dt);
      _updatePositionToZero(dt);
    } else {
      _scaleToParentSizeMax(dt);
      _updatePositionToOriginalSize(dt);
    }

    super.update(dt);
  }

  void _updateAlphaByDistance(double distanceToPlayer, double dt) {
    final t = (distanceToPlayer / PhysicsTuning.birdShadowMaxDistance).clamp(
      0.0,
      1.0,
    );
    double alpha =
        PhysicsTuning.birdShadowMaxAlpha +
        (PhysicsTuning.birdShadowMinAlpha - PhysicsTuning.birdShadowMaxAlpha) *
            t;
    if (distanceToPlayer <= PhysicsTuning.birdShadowFadeOutEndDistance) {
      alpha = 0.0;
    }
    _animations.paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..blendMode = BlendMode.multiply;
  }

  void _scaleToParentSize(double dt) {
    final currentSize = size;
    final parentSize = (parent as PositionComponent).size;
    final factor = (dt * PhysicsTuning.birdShadowScaleSpeed).clamp(0.0, 1.0);
    final updatedSize = Vector2(
      (currentSize.x + (parentSize.x - currentSize.x) * factor).clamp(
        parentSize.x,
        parentSize.x * PhysicsTuning.birdShadowMaxSizeMultiplier,
      ),
      (currentSize.y + (parentSize.y - currentSize.y) * factor).clamp(
        parentSize.y,
        parentSize.y * PhysicsTuning.birdShadowMaxSizeMultiplier,
      ),
    );
    _animations.size = updatedSize;
    size = updatedSize;
  }

  void _scaleToParentSizeMax(double dt) {
    final currentSize = size;
    final parentSize = (parent as PositionComponent).size;
    final targetSize = parentSize * PhysicsTuning.birdShadowMaxSizeMultiplier;
    final factor = (dt * PhysicsTuning.birdShadowRetractScaleSpeed).clamp(
      0.0,
      1.0,
    );
    final updatedSize = Vector2(
      (currentSize.x + (targetSize.x - currentSize.x) * factor).clamp(
        parentSize.x,
        parentSize.x * PhysicsTuning.birdShadowMaxSizeMultiplier,
      ),
      (currentSize.y + (targetSize.y - currentSize.y) * factor).clamp(
        parentSize.y,
        parentSize.y * PhysicsTuning.birdShadowMaxSizeMultiplier,
      ),
    );
    size = updatedSize;
    _animations.size = updatedSize;
  }

  void _updatePositionToZero(double dt) {
    final parentSize = (parent as PositionComponent).size;
    final target = Vector2(
      parentSize.x / 2 + PhysicsTuning.birdShadowPositionOffsetX,
      parentSize.y / 2 + PhysicsTuning.birdShadowPositionOffsetY,
    );
    final factor = dt * PhysicsTuning.birdShadowPositionLerpSpeed;
    position = Vector2(
      (position.x + (target.x - position.x) * factor).clamp(
        parentSize.x / 2,
        parentSize.x / 2 + PhysicsTuning.birdShadowPositionOffsetX,
      ),
      (position.y + (target.y - position.y) * factor).clamp(
        parentSize.y / 2,
        parentSize.y / 2 + PhysicsTuning.birdShadowPositionOffsetY,
      ),
    );
  }

  void _updatePositionToOriginalSize(double dt) {
    final parentSize = (parent as PositionComponent).size;
    final target = parentSize / 2;
    final factor = dt * PhysicsTuning.birdShadowPositionLerpSpeed;
    position = Vector2(
      (position.x + (target.x - position.x) * factor).clamp(
        parentSize.x / 2,
        parentSize.x / 2 + PhysicsTuning.birdShadowPositionOffsetX,
      ),
      (position.y + (target.y - position.y) * factor).clamp(
        parentSize.y / 2,
        parentSize.y / 2 + PhysicsTuning.birdShadowPositionOffsetY,
      ),
    );
  }
}
