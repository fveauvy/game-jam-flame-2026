import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/components/enemies/bird_enemy_component.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/my_game.dart';

enum ShadowType { max, min, normal }

class ShadowComponent extends SpriteAnimationGroupComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  ShadowComponent({super.position, required super.size}) : super(priority: 10);

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
    final player = game.world.children.whereType<PlayerComponent>().firstOrNull;
    if (player == null || game.paused) {
      super.update(dt);
      return;
    }
    final distanceToPlayer = (parent as PositionComponent).position.distanceTo(
      player.position,
    );
    if (distanceToPlayer > 600) {
      _animations.current = ShadowType.max;
    } else if (distanceToPlayer > 450) {
      _animations.current = ShadowType.normal;
    } else {
      _animations.current = ShadowType.min;
    }
    if (distanceToPlayer < 150) {
      (parent as BirdComponent).startAttack();
    }

    _updateAlphaByDistance(distanceToPlayer, dt);

    if (distanceToPlayer < 600) {
      _scaleToParentSize(dt);
      _updatePositionToZero(dt);
    } else {
      _scaleToParentSizeMax(dt);
      _updatePositionToOriginalSize(dt);
    }

    super.update(dt);
  }

  void _updateAlphaByDistance(double distanceToPlayer, double dt) {
    const double fadeInStart = 600.0;
    const double peakDistance = 300.0;
    const double fadeOutEnd = 100.0;
    late final double alpha;
    if (distanceToPlayer <= fadeOutEnd) {
      alpha = 0.0;
    } else if (distanceToPlayer >= fadeInStart) {
      alpha = 1;
    } else if (distanceToPlayer >= peakDistance) {
      alpha =
          1.0 -
          (distanceToPlayer - peakDistance) / (fadeInStart - peakDistance);
    } else {
      alpha = (distanceToPlayer - fadeOutEnd) / (peakDistance - fadeOutEnd);
    }
    _animations.paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..blendMode = BlendMode.multiply;
  }

  void _scaleToParentSize(double dt) {
    final currentSize = size;
    final double scaleSpeed = 2; // fraction per second toward target (lerp)
    final parentSize = (parent as PositionComponent).size;
    final targetSize = parentSize.clone();
    final factor = (dt * scaleSpeed).clamp(0.0, 1.0);
    final xScale = (currentSize.x + (targetSize.x - currentSize.x) * factor)
        .clamp(parentSize.x, parentSize.x * 1.5);
    final yScale = (currentSize.y + (targetSize.y - currentSize.y) * factor)
        .clamp(parentSize.y, parentSize.y * 1.5);
    final updatedSize = Vector2(xScale, yScale);
    _animations.size = updatedSize;
    size = updatedSize;
  }

  void _scaleToParentSizeMax(double dt) {
    final currentSize = size;
    final double scaleSpeed = 1;
    final parentSize = (parent as PositionComponent).size;
    final targetSize = parentSize * 1.5;
    final factor = (dt * scaleSpeed).clamp(0.0, 1.0);
    final xScale = (currentSize.x + (targetSize.x - currentSize.x) * factor)
        .clamp(parentSize.x, parentSize.x * 1.5);
    final yScale = (currentSize.y + (targetSize.y - currentSize.y) * factor)
        .clamp(parentSize.y, parentSize.y * 1.5);
    final updatedSize = Vector2(xScale, yScale);
    size = updatedSize;
    _animations.size = updatedSize;
  }

  void _updatePositionToZero(double dt) {
    final parentSize = (parent as PositionComponent).size;
    final target = Vector2(parentSize.x / 2 + 50.0, parentSize.y / 2 + 25.0);
    final factor = dt * 0.5;
    position = Vector2(
      (position.x + (target.x - position.x) * factor).clamp(
        parentSize.x / 2,
        parentSize.x / 2 + 50.0,
      ),
      (position.y + (target.y - position.y) * factor).clamp(
        parentSize.y / 2,
        parentSize.y / 2 + 25.0,
      ),
    );
  }

  void _updatePositionToOriginalSize(double dt) {
    final parentSize = (parent as PositionComponent).size;
    final target = parentSize / 2;
    final factor = dt * 0.5;
    position = Vector2(
      (position.x + (target.x - position.x) * factor).clamp(
        parentSize.x / 2,
        parentSize.x / 2 + 50.0,
      ),
      (position.y + (target.y - position.y) * factor).clamp(
        parentSize.y / 2,
        parentSize.y / 2 + 25.0,
      ),
    );
  }
}
