import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/physics_tuning.dart';
import 'package:game_jam/game/my_game.dart';

class BirdAnimationComponent extends SpriteAnimationComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  BirdAnimationComponent({required super.position})
    : super(priority: 130, size: _zeroSize);

  static final _zeroSize = Vector2.zero();
  Vector2 get _originalSize => (parent as PositionComponent).size;
  final _megaSize = Vector2(
    PhysicsTuning.birdEnemyMegaSizeWidth,
    PhysicsTuning.birdEnemyMegaSizeHeight,
  );

  bool _isAttacking = false;
  bool isRetreating = false;
  bool _updateSizeForAttack = false;

  bool get canApplyDamage =>
      !isRetreating &&
      size.x < (_originalSize.x + 5) &&
      size.y < (_originalSize.y + 5);

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.variableSpriteList(
      [
        Sprite(
          game.images.fromCache(AssetPaths.birdAnimatedSpriteCacheKey(1)),
          srcSize: Vector2(1073, 536),
        ),
        Sprite(
          game.images.fromCache(AssetPaths.birdAnimatedSpriteCacheKey(2)),
          srcSize: Vector2(1073, 536),
        ),
      ],
      stepTimes: [0.5, 0.5],
    );
    paint = Paint()..color = Colors.transparent.withValues(alpha: 1);
    anchor = Anchor.center;

    await super.onLoad();
  }

  @override
  void update(double dt) {
    if (game.paused) {
      super.update(dt);
      return;
    }
    if (_updateSizeForAttack) {
      size = _megaSize;
      paint = Paint()..color = Colors.white.withValues(alpha: 1.0);
      _updateSizeForAttack = false;
      _isAttacking = true;
    }
    if (_isAttacking) {
      _scaleToOriginalSize(dt);
    }
    if (isRetreating) {
      _scaleToMegaSize(dt);
      _fadeOut(dt);
      if (paint.color.a <= 0.01) {
        size = Vector2.zero();
        isRetreating = false;
      }
    }
    super.update(dt);
  }

  void startAttack() {
    isRetreating = false;
    _updateSizeForAttack = true;
  }

  void startRetreat() {
    _isAttacking = false;
    _updateSizeForAttack = false;
    isRetreating = true;
  }

  void _scaleToOriginalSize(double dt) {
    final currentSize = size;
    final targetSize = _originalSize.clone();
    final factor = (dt * PhysicsTuning.birdEnemyScaleSpeed).clamp(0.0, 1.0);
    final xScale = (currentSize.x + (targetSize.x - currentSize.x) * factor)
        .clamp(_originalSize.x, _megaSize.x);
    final yScale = (currentSize.y + (targetSize.y - currentSize.y) * factor)
        .clamp(_originalSize.y, _megaSize.y);
    final updatedSize = Vector2(xScale, yScale);
    size = updatedSize;
  }

  void _scaleToMegaSize(double dt) {
    final currentSize = size;
    final factor = (dt * PhysicsTuning.birdEnemyScaleSpeed).clamp(0.0, 1.0);
    size = Vector2(
      (currentSize.x + (_megaSize.x - currentSize.x) * factor).clamp(
        currentSize.x,
        _megaSize.x,
      ),
      (currentSize.y + (_megaSize.y - currentSize.y) * factor).clamp(
        currentSize.y,
        _megaSize.y,
      ),
    );
  }

  void _fadeOut(double dt) {
    final newAlpha = (paint.color.a - dt * PhysicsTuning.birdEnemyFadeOutSpeed)
        .clamp(0.0, 1.0);
    paint = Paint()..color = Colors.white.withValues(alpha: newAlpha);
  }
}
