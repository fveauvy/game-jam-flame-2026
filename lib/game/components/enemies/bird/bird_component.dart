import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/core/config/physics_tuning.dart';
import 'package:game_jam/core/entities/player_vertical_position.dart';
import 'package:game_jam/game/components/enemies/bird/bird_animation_component.dart';
import 'package:game_jam/game/components/enemies/bird/bird_shadow_component.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/my_game.dart';
import 'package:game_jam/game/utils/position_component_extension.dart';

class BirdComponent extends PositionComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  BirdComponent({required super.position, required super.size})
    : super(priority: 120);

  static const double attackSpeed = PhysicsTuning.birdEnemyAttackSpeed;
  static const double speed = PhysicsTuning.birdEnemySpeed;

  late final BirdShadowComponent _shadow;
  late final BirdAnimationComponent _bird;

  final _maxEggs = GameplayTuning.initialEggCount / 5;

  bool _isAttacking = false;

  static final _startPosition = Vector2(GameConfig.worldSize.x - 200, 100);

  @override
  Future<void> onLoad() async {
    _shadow = BirdShadowComponent(position: size / 2, size: size * 1.5);
    _bird = BirdAnimationComponent(position: size / 2);
    add(_shadow);
    add(_bird);
    add(CircleHitbox(radius: size.x / 4));

    await super.onLoad();
  }

  @override
  void update(double dt) {
    if (!shouldRunForPhase(game.phase.value)) {
      super.update(dt);
      return;
    }
    final PlayerComponent? player = game.world.player;
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
        _bird.canApplyDamage) {
      unawaited(
        other.applyDamageWithInvincibilityDelay(
          PhysicsTuning.birdEnemyDamageAmount,
          PhysicsTuning.birdEnemyDamageInvincibilitySeconds,
        ),
      );
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
    final PlayerComponent? player = game.world.player;
    if (_isAttacking ||
        player == null ||
        player.levelPosition == PlayerVerticalPosition.underwater) {
      return;
    }
    _isAttacking = true;
    unawaited(game.playSfx(AssetPaths.birdDiveSfx, volume: 0.8));
    _bird.startAttack();
  }

  void finishAttack() {
    _isAttacking = false;
    _bird.startRetreat();
  }

  void resetForNewRun() {
    position = _startPosition.clone();
    _isAttacking = false;
  }

  static bool shouldRunForPhase(GamePhase phase) {
    return phase == GamePhase.playing;
  }
}
