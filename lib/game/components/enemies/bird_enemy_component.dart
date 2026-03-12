import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/core/config/physics_tuning.dart';
import 'package:game_jam/core/entities/player_vertical_position.dart';
import 'package:game_jam/game/components/environment/fly_animation_definition.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/components/utils/shadow_component.dart';
import 'package:game_jam/game/my_game.dart';
import 'package:game_jam/game/utils/position_component_extension.dart';

class BirdComponent extends PositionComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  BirdComponent({required super.position, required super.size})
    : super(priority: 120);

  static const double attackSpeed = 300;
  static const double speed = 100;

  late final ShadowComponent _shadow;
  late final BirdEnemyComponent _bird;

  final _maxEggs = GameplayTuning.initialEggCount / 5;

  bool _isAttacking = false;

  static final _startPosition = Vector2(GameConfig.worldSize.x - 200, 100);

  @override
  Future<void> onLoad() async {
    _shadow = ShadowComponent(position: size / 2, size: size * 1.5);
    _bird = BirdEnemyComponent(position: size / 2);
    add(_shadow);
    add(_bird);
    add(CircleHitbox(radius: size.x / 2));

    await super.onLoad();
  }

  @override
  void update(double dt) {
    final player = game.world.children.whereType<PlayerComponent>().firstOrNull;
    if (player == null || game.paused) {
      super.update(dt);
      return;
    }

    final eggCount = game.gameState.savedEggs;
    final speedToAdd = ((eggCount / _maxEggs).toInt()).clamp(1, 5) * 50;

    if (player.levelPosition == PlayerVerticalPosition.underwater) {
      _moveTowardStartPosition(dt);
    } else {
      followComponent(speed + speedToAdd, dt, player);
      _updateFacing(player, dt);
    }

    if (player.levelPosition == PlayerVerticalPosition.underwater &&
        _isAttacking) {
      finishAttack();
    }

    super.update(dt);
  }

  @override
  Future<void> onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) async {
    if (other is PlayerComponent &&
        intersectionPoints.length >= 2 &&
        !_bird.isRetreating) {
      unawaited(other.applyDamageWithInvincibilityDelay(10, 5));
    }
    super.onCollision(intersectionPoints, other);
  }

  void _moveTowardStartPosition(double dt) {
    final direction = _startPosition - position;
    final distance = direction.length;
    if (distance < 1.0) {
      position = _startPosition.clone();
      return;
    }
    direction.normalize();
    position += direction * min(speed * dt, distance);
    _applyFacingFromDirection(direction, dt);
  }

  void _updateFacing(PlayerComponent player, double dt) {
    final direction = player.absoluteCenter - absoluteCenter;
    if (direction.length < 1e-4) return;
    direction.normalize();
    _applyFacingFromDirection(direction, dt);
  }

  void _applyFacingFromDirection(Vector2 normalizedDirection, double dt) {
    final targetAngle = atan2(normalizedDirection.x, -normalizedDirection.y);
    final double angleDelta = _shortestAngleDelta(targetAngle, _bird.angle);
    if (angleDelta.abs() > 1e-4) {
      final double maxStep = PhysicsTuning.birdEnemyRotationSpeed * dt;
      if (angleDelta.abs() <= maxStep) {
        _bird.angle = _normalizeAngle(targetAngle);
      } else {
        _bird.angle = _normalizeAngle(_bird.angle + angleDelta.sign * maxStep);
      }
      _shadow.angle = _bird.angle;
    }
  }

  static double _normalizeAngle(double value) {
    final double twoPi = 2 * pi;
    final double normalized = value % twoPi;
    if (normalized < 0) {
      return normalized + twoPi;
    }
    return normalized;
  }

  static double _shortestAngleDelta(double target, double current) {
    final double twoPi = 2 * pi;
    double delta = (target - current) % twoPi;
    if (delta > pi) {
      delta -= twoPi;
    } else if (delta < -pi) {
      delta += twoPi;
    }
    return delta;
  }

  void startAttack() {
    final player = game.world.children.whereType<PlayerComponent>().firstOrNull;
    if (_isAttacking ||
        player == null ||
        player.levelPosition == PlayerVerticalPosition.underwater) {
      return;
    }
    _isAttacking = true;
    _bird.startAttack();
  }

  void finishAttack() {
    _isAttacking = false;
    _bird.startRetreat();
  }
}

class BirdEnemyComponent extends SpriteAnimationComponent
    with HasGameReference<MyGame>, FlyAnimationDefinition, CollisionCallbacks {
  BirdEnemyComponent({required super.position})
    : super(priority: 130, size: _zeroSize);

  static final _zeroSize = Vector2.zero();
  Vector2 get _originalSize => (parent as PositionComponent).size;
  final _megaSize = Vector2(1000, 1100);

  bool _isAttacking = false;
  bool isRetreating = false;
  bool _updateSizeForAttack = false;

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
    final double scaleSpeed = 2;

    final targetSize = _originalSize.clone();
    final factor = (dt * scaleSpeed).clamp(0.0, 1.0);
    final xScale = (currentSize.x + (targetSize.x - currentSize.x) * factor)
        .clamp(_originalSize.x, _megaSize.x);
    final yScale = (currentSize.y + (targetSize.y - currentSize.y) * factor)
        .clamp(_originalSize.y, _megaSize.y);
    final updatedSize = Vector2(xScale, yScale);
    size = updatedSize;
  }

  void _scaleToMegaSize(double dt) {
    final currentSize = size;
    const double scaleSpeed = 2;
    final factor = (dt * scaleSpeed).clamp(0.0, 1.0);
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
    final newAlpha = (paint.color.a - dt * 1.5).clamp(0.0, 1.0);
    paint = Paint()..color = Colors.white.withValues(alpha: newAlpha);
  }
}
