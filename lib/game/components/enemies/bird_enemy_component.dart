import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/core/config/physics_tuning.dart';
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

  final _maxEggs = GameplayTuning.initialEggCount / 3;

  bool _isAttacking = false;

  @override
  Future<void> onLoad() async {
    _shadow = ShadowComponent(position: size / 2, size: size * 1.5);
    _bird = BirdEnemyComponent(position: size / 2);
    add(_shadow);
    add(_bird);

    await super.onLoad();
  }

  @override
  void update(double dt) {
    final eggCount = game.gameState.savedEggs;
    final speedMultiplier = ((eggCount / _maxEggs).toInt()).clamp(1, 3);
    final player = game.world.children.whereType<PlayerComponent>().firstOrNull;
    if (player == null) {
      super.update(dt);
      return;
    }

    followComponent(
      _isAttacking ? (attackSpeed * speedMultiplier) : speed,
      dt,
      player,
    );
    _updateFacing(player, dt);

    super.update(dt);
  }

  void _updateFacing(PlayerComponent player, double dt) {
    final direction = player.absoluteCenter - absoluteCenter;
    if (direction.length < 1e-4) return;
    final targetAngle = atan2(direction.x, -direction.y);
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
    if (_isAttacking) return;
    _isAttacking = true;
    _bird.startAttack();
  }

  void finishAttack() {
    _isAttacking = false;
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
    super.update(dt);
    if (_updateSizeForAttack) {
      size = _megaSize;
      _updateSizeForAttack = false;
      _isAttacking = true;
    }
    if (_isAttacking) {
      _scaleToOriginalSize(dt);
    }
    super.update(dt);
  }

  void startAttack() {
    _updateSizeForAttack = true;
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
}
