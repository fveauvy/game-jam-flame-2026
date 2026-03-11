import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/physics_tuning.dart';
import 'package:game_jam/game/components/environment/fly_animation_definition.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/components/utils/shadow_component.dart';
import 'package:game_jam/game/my_game.dart';
import 'package:game_jam/game/utils/position_component_extension.dart';

class BirdEnemyComponent extends SpriteAnimationComponent
    with HasGameReference<MyGame>, FlyAnimationDefinition, CollisionCallbacks {
  final Vector2 initialPosition;
  final Vector2 initialSize;

  late final Random _random = game.random;
  static const double _speed = PhysicsTuning.birdEnemySpeed;
  static const double _directionChangeInterval =
      PhysicsTuning.birdEnemyDirectionChangeInterval;
  static const double _margin = PhysicsTuning.birdEnemyMargin;

  /// Min horizontal distance to target before we change facing (avoids flip jitter when on top of player).
  static const double _facingFlipDeadZone =
      PhysicsTuning.birdEnemyFacingFlipDeadZone;
  static final minSize = Vector2.all(10);
  static const double _scaleUpDistance = PhysicsTuning.birdEnemyScaleUpDistance;

  Vector2 _velocity = Vector2.zero();
  double _directionChangeTimer = 0;

  BirdEnemyComponent({required this.initialPosition, required this.initialSize})
    : super(priority: 100, size: minSize, position: initialPosition);

  PositionComponent? _target;
  bool _isScaled = false;

  /// When true, only the shadow is visible and moves; bird appears when player hovers.
  bool _shadowOnlyPhase = true;

  /// 0..1 during descent (shadow "becomes" bird); null when not descending.
  double? _descentProgress;
  static const double _descentDuration = PhysicsTuning.birdEnemyDescentDuration;

  /// Vertical distance the bird descends from (creates sense of height).
  static const double _descentHeight = PhysicsTuning.birdEnemyDescentHeight;
  double _shadowPulseTime = 0;

  /// World position of the shadow center when descent started (merge point).
  Vector2? _descentStartCenter;

  /// 0..1 during ascend (reverse merge: bird leaves, shadow returns); null when not ascending.
  double? _ascendProgress;
  Vector2? _ascendStartCenter;

  /// Time remaining before next damage can be applied (seconds).
  double _damageCooldown = 0;
  static const double _damageInterval = PhysicsTuning.birdEnemyDamageInterval;
  static const double _damageRange = PhysicsTuning.birdEnemyDamageRange;
  static const int _damageAmount = PhysicsTuning.birdEnemyDamageAmount;

  static bool shouldRunForPhase(GamePhase phase) {
    return phase == GamePhase.playing;
  }

  /// Set when we finish ascend: we remove shadow/hitbox but defer adding new
  /// ones to the next frame so Flame's collision system sees the pair end
  /// before the new hitbox is added (fixes "collision only once").
  bool _pendingRecreateShadowAndHitbox = false;

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('fly.png'),
      animationData,
    );
    _pickNewDirection();

    add(
      CircleHitbox(
        radius: initialSize.x,
        position: Vector2(initialSize.x, initialSize.y),
      ),
    );
    add(
      ShadowComponent(
        position: _shadowPositionFor(size: initialSize, facingRight: true),
        radius: initialSize.x,
      ),
    );

    await super.onLoad();
  }

  void _pickNewDirection() {
    final angle = _random.nextDouble() * 2 * pi;
    _velocity = Vector2(cos(angle), sin(angle)) * _speed;
  }

  @override
  Future<void> update(double dt) async {
    if (!shouldRunForPhase(game.phase.value)) {
      super.update(dt);
      return;
    }

    if (_pendingRecreateShadowAndHitbox) {
      _pendingRecreateShadowAndHitbox = false;
      // Defer add until after this frame's update tree and collisionDetection.run()
      // so the collision system sees the pair as ended before the new hitbox exists.
      // ignore: unawaited_futures
      Future.microtask(_recreateShadowAndHitboxForShadowOnly);
    }

    final target = _target;

    _damageCooldown = (_damageCooldown - dt).clamp(0.0, _damageInterval);

    final distanceToTarget = target != null
        ? position.distanceTo(target.position)
        : double.infinity;

    if (distanceToTarget <= _damageRange &&
        target is PlayerComponent &&
        _damageCooldown <= 0) {
      target.applyDamage(_damageAmount);
      _damageCooldown = _damageInterval;
    }

    if (_shadowOnlyPhase) {
      _updateShadowOnly(dt);
      super.update(dt);
      return;
    }
    if (_updateDescent(dt, target)) {
      super.update(dt);
      return;
    }
    if (target != null) {
      _updateChase(dt, target);
      super.update(dt);
      return;
    }
    if (_updateAscend(dt)) {
      super.update(dt);
      return;
    }

    _updateWandering(dt);
    super.update(dt);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is PlayerComponent && !other.isInWater) {
      if (_shadowOnlyPhase) {
        _shadowOnlyPhase = false;
        _target = other;
        _descentProgress = 0;
      } else {
        _target = other;
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _updateShadowOnly(double dt) {
    paint = Paint()..color = Colors.transparent;
    _updateMovingShadow(dt);
    _animateShadowPulse(dt);
  }

  /// Returns true if still in descent (caller should return).
  bool _updateDescent(double dt, PositionComponent? target) {
    if (_descentProgress == null || _descentProgress! >= 1) return false;

    _descentStartCenter ??= position + Vector2(initialSize.x, initialSize.y);
    if (target != null) {
      _descentStartCenter = _moveCenterTowardTarget(
        _descentStartCenter!,
        target,
        dt,
      );
    }
    _descentProgress = (_descentProgress! + dt / _descentDuration).clamp(
      0.0,
      1.0,
    );
    final t = _descentProgress!;
    _applyMergeState(mergeCenter: _descentStartCenter!, t: t);

    if (_descentProgress! >= 1) {
      _finishDescent();
    }
    return true;
  }

  void _updateChase(double dt, PositionComponent target) {
    if (target is PlayerComponent && target.isInWater) {
      _target = null;
      _ascendStartCenter = position + size / 2;
      _ascendProgress = 0;
      return;
    }
    _updateFacingToward(target);
    followComponent(_speed, dt, target);
    _scaleUpComponent(target);
    _scaleDownShadow(target);
    final shadow = children.whereType<ShadowComponent>().firstOrNull;
    if (shadow != null) {
      shadow.position = _shadowPositionFor(size: size);
    }
  }

  /// Returns true if still ascending (caller should return).
  bool _updateAscend(double dt) {
    if (_ascendProgress == null || _ascendProgress! >= 1) return false;

    _ascendProgress = (_ascendProgress! + dt / _descentDuration).clamp(
      0.0,
      1.0,
    );
    final t = 1 - _ascendProgress!;
    _applyMergeState(mergeCenter: _ascendStartCenter!, t: t);

    if (_ascendProgress! >= 1) {
      _finishAscend();
    }
    return true;
  }

  void _updateWandering(double dt) {
    _directionChangeTimer -= dt;
    if (_directionChangeTimer <= 0) {
      _directionChangeTimer =
          _directionChangeInterval + (_random.nextDouble() - 0.5) * 0.8;
      _pickNewDirection();
    }
    position += _velocity * dt;
    final bounds = GameConfig.worldSize;
    position.x = position.x.clamp(_margin, bounds.x - _margin);
    position.y = position.y.clamp(_margin, bounds.y - _margin);
    if (_velocity.x != 0) {
      scale.x = _velocity.x < 0 ? -1 : 1;
    }
  }

  /// Applies size, position, paint and shadow for a merge state (descent or ascend).
  void _applyMergeState({required Vector2 mergeCenter, required double t}) {
    size = minSize + (initialSize - minSize) * t;
    final verticalOffset = _descentHeight * (1 - t);
    final birdCenter = mergeCenter + Vector2(0, -verticalOffset);
    position = birdCenter - size / 2;
    paint = Paint()..color = Colors.white.withValues(alpha: t);

    final shadow = children.whereType<ShadowComponent>().firstOrNull;
    if (shadow != null) {
      shadow.position = mergeCenter - position;
      shadow.scale = Vector2.all(1 - t);
      shadow.paint = Paint()
        ..color = Colors.black.withValues(alpha: (1 - t).clamp(0.0, 0.5));
    }
  }

  void _finishDescent() {
    _isScaled = true;
    _descentProgress = null;
    final shadow = children.whereType<ShadowComponent>().firstOrNull;
    if (shadow != null) {
      shadow.position = _shadowPositionFor(size: initialSize);
      shadow.scale = Vector2.all(1);
    }
    final hitbox = children.whereType<CircleHitbox>().firstOrNull;
    if (hitbox != null) {
      hitbox.position = initialSize / 2;
    }
    _descentStartCenter = null;
  }

  void _finishAscend() {
    _shadowOnlyPhase = true;
    _isScaled = false;
    _ascendProgress = null;
    _descentProgress = null;
    _descentStartCenter = null;

    final center = _ascendStartCenter!;
    _ascendStartCenter = null;
    position = center - Vector2(initialSize.x, initialSize.y);

    _pickNewDirection();

    _removeShadowAndHitbox();
    _pendingRecreateShadowAndHitbox = true;
  }

  /// Removes shadow and hitbox so the collision system can clear the active
  /// pair (bird hitbox, player). Called when finishing ascend.
  void _removeShadowAndHitbox() {
    final shadow = children.whereType<ShadowComponent>().firstOrNull;
    final hitbox = children.whereType<CircleHitbox>().firstOrNull;
    shadow?.removeFromParent();
    hitbox?.removeFromParent();
  }

  /// Re-adds shadow and hitbox. Called at the start of the next frame after
  /// _removeShadowAndHitbox so Flame's collision run sees the pair ended
  /// before the new hitbox exists (fixes "collision only once").
  Future<void> _recreateShadowAndHitboxForShadowOnly() async {
    add(
      CircleHitbox(
        radius: initialSize.x,
        position: Vector2(initialSize.x, initialSize.y),
      ),
    );
    add(
      ShadowComponent(
        position: Vector2(initialSize.x, initialSize.y),
        radius: initialSize.x,
      ),
    );
  }

  void _updateFacingToward(PositionComponent target) {
    final dx = target.absoluteCenter.x - absoluteCenter.x;
    if (dx < -_facingFlipDeadZone && scale.x >= 0) {
      scale.x = -1;
    } else if (dx > _facingFlipDeadZone && scale.x <= 0) {
      scale.x = 1;
    }
  }

  void _updateMovingShadow(double dt) {
    _directionChangeTimer -= dt;
    if (_directionChangeTimer <= 0) {
      _directionChangeTimer =
          _directionChangeInterval + (_random.nextDouble() - 0.5) * 0.8;
      _pickNewDirection();
    }
    position += _velocity * dt;
    final bounds = GameConfig.worldSize;
    position.x = position.x.clamp(_margin, bounds.x - _margin);
    position.y = position.y.clamp(_margin, bounds.y - _margin);
  }

  void _animateShadowPulse(double dt) {
    _shadowPulseTime += dt;
    final shadow = children.whereType<ShadowComponent>().firstOrNull;
    if (shadow == null) return;
    final pulse = 0.92 + 0.08 * (1 + sin(_shadowPulseTime * 3));
    shadow.scale = Vector2.all(pulse);
  }

  /// Shadow below the sprite, offset in the direction the bird is facing.
  Vector2 _shadowPositionFor({required Vector2 size, bool? facingRight}) {
    final dir = (facingRight ?? scale.x >= 0) ? 1.0 : -1.0;
    return Vector2(size.x / 2 + (size.x * 0.2) * dir, size.y);
  }

  static const double _followEpsilon = 1e-3;

  Vector2 _moveCenterTowardTarget(
    Vector2 center,
    PositionComponent target,
    double dt,
  ) {
    final direction = target.absoluteCenter - center;
    if (direction.length < _followEpsilon) return center;
    final newCenter = center + direction.normalized() * _speed * dt;
    final bounds = GameConfig.worldSize;
    return Vector2(
      newCenter.x.clamp(_margin, bounds.x - _margin),
      newCenter.y.clamp(_margin, bounds.y - _margin),
    );
  }

  void _scaleDownShadow(PositionComponent target) {
    if (_isScaled) return;
    final shadow = children.whereType<ShadowComponent>().firstOrNull;
    if (shadow == null) return;
    final distance = position.distanceTo(target.position);
    final t = 1 - (distance / _scaleUpDistance).clamp(0.0, 1.0);
    shadow.paint = Paint()
      ..color = Colors.black.withValues(alpha: (1 - t).clamp(0.0, 0.5));
    if (distance <= 0) {
      shadow.paint = Paint()..color = Colors.transparent;
    }
  }

  void _scaleUpComponent(PositionComponent target) {
    if (_isScaled) return;
    final distance = position.distanceTo(target.position);
    if (distance >= _scaleUpDistance) {
      return;
    }
    final t = 1 - (distance / _scaleUpDistance).clamp(0.0, 1.0);
    size = minSize + (initialSize - minSize) * t;
    paint = Paint()..color = Colors.black.withValues(alpha: 1 * t);
    if (distance <= 0) {
      paint = Paint()..color = Colors.black.withValues(alpha: 1);
      size = initialSize;
      _isScaled = true;
    }
  }
}
