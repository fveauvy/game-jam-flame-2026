import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/physics_tuning.dart';
import 'package:game_jam/core/entities/player_vertical_position.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/components/allies/egg_component.dart';
import 'package:game_jam/game/components/environment/frog_house_component.dart';
import 'package:game_jam/game/components/environment/ground_component.dart';
import 'package:game_jam/game/components/environment/thorn_component.dart';
import 'package:game_jam/game/components/environment/water_component.dart';
import 'package:game_jam/game/components/environment/water_lily_component.dart';
import 'package:game_jam/game/components/player/player_animation_extention.dart';
import 'package:game_jam/game/components/text/simple_text_component.dart';
import 'package:game_jam/game/input/input_state.dart';
import 'package:game_jam/game/my_game.dart';

class PlayerComponent extends SpriteAnimationComponent
    with HasGameReference<MyGame>, CollisionCallbacks, TapCallbacks {
  PlayerComponent({
    required this.inputState,
    required CharacterProfile profile,
    required Vector2 startPosition,
    double speedMultiplier = 1.0,
    double sizeMultiplier = 1.0,
  }) : _startPosition = startPosition.clone(),
       _profile = profile,
       _baseSpeedMultiplier = speedMultiplier,
       _baseSizeMultiplier = sizeMultiplier,
       super(
         position: startPosition.clone(),
         size: Vector2.all(PhysicsTuning.playerBaseSize),
         anchor: Anchor.center,
         priority: 110,
       ) {
    _applyStatsFromProfile();
    previousPosition = inputState.playerVerticalPosition;
  }

  static const Duration _damageTextDuration = Duration(seconds: 1);
  static const Duration _damageTextDelay = Duration(milliseconds: 500);
  static const int _defaultHealth = 100;

  final InputState inputState;
  final Vector2 _startPosition;
  final double _baseSpeedMultiplier;
  final double _baseSizeMultiplier;

  CharacterProfile _profile;
  double _spriteOpacity = 1.0;
  CircleHitbox? _hitbox;
  late double _speedMultiplier;
  late double _sizeMultiplier;
  late int _maxHealth;
  late int _remainingHealth;
  late double _hopTime;
  PlayerVerticalPosition get levelPosition => inputState.playerVerticalPosition;
  late PlayerVerticalPosition previousPosition;
  double get moveSpeed => PhysicsTuning.playerMoveSpeed;

  CharacterProfile get profile => _profile;
  int get maxHealth => _maxHealth;
  int get remainingHealth => _remainingHealth;

  bool _isDamageTextVisible = false;
  bool isInWater = false;
  int _waterContacts = 0;
  int _frogHouseContacts = 0;
  int _groundContacts = 0;
  int _lilyContacts = 0;
  bool _jumpActive = false;
  double _jumpElapsed = 0;
  double _underwaterSurfaceGraceRemaining = 0;
  Vector2 _jumpDirection = Vector2.zero();
  final Vector2 _thornKnockbackVelocity = Vector2.zero();
  double _thornInvincibilityRemaining = 0;
  double _thornFlickerElapsed = 0;

  int eggsCollected = 0;

  bool get _isTouchingGround => _groundContacts > 0;
  bool get _isTouchingLily => _lilyContacts > 0;
  bool get _isTouchingFrogHouse => _frogHouseContacts > 0;

  bool get _isMoving => velocity.length2 > 0;
  bool _wasMoving = false;

  Vector2 get velocity =>
      normalizeMoveAxis(inputState.moveAxisX, inputState.moveAxisY);

  @override
  void onTapDown(TapDownEvent event) {
    // In the menu, tapping a frog selects it and starts the game.
    if (game.phase.value == GamePhase.menu) {
      game.onPlayerTapped(this);
    }
    super.onTapDown(event);
  }

  @override
  Future<void> onMount() async {
    super.onMount();
    paint = Paint()
      ..color = Colors.white.withAlpha((_spriteOpacity * 255).toInt());
    _hitbox = CircleHitbox(
      radius: (size.x / 3),
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
    // Players always spawn on land; initialise the shared input state so that
    // the correct animation, size and physics are applied from frame 1.
    inputState.playerVerticalPosition = PlayerVerticalPosition.land;
    previousPosition = PlayerVerticalPosition.land;
    animation = idleAnimation(levelPosition);
    await add(_hitbox!);
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

  void applyProfile(CharacterProfile profile) {
    _profile = profile;
    _applyStatsFromProfile();
    animation = idleAnimation(levelPosition);
  }

  void _applyStatsFromProfile() {
    _speedMultiplier = (_profile.traits.speed ?? _baseSpeedMultiplier).clamp(
      PhysicsTuning.minSpeedMultiplier,
      PhysicsTuning.maxSpeedMultiplier,
    );
    _sizeMultiplier = (_profile.traits.size ?? _baseSizeMultiplier).clamp(
      PhysicsTuning.minSizeMultiplier,
      PhysicsTuning.maxSizeMultiplier,
    );
    _maxHealth = resolveMaxHealth(_profile);
    _remainingHealth = _maxHealth;
    size = Vector2.all(PhysicsTuning.playerBaseSize * _sizeMultiplier);
    _syncHitbox();
  }

  void _syncHitbox() {
    final CircleHitbox? hitbox = _hitbox;
    if (hitbox == null) {
      return;
    }
    hitbox.radius = size.x / 2;
  }

  static int resolveMaxHealth(CharacterProfile profile) {
    final int? health = profile.traits.health;
    if (health == null) {
      return _defaultHealth;
    }
    return health.clamp(1, 9999);
  }

  static Vector2 normalizeMoveAxis(double axisX, double axisY) {
    final Vector2 velocity = Vector2(axisX, axisY);
    if (velocity.length2 > 1) {
      velocity.normalize();
    }
    return velocity;
  }

  static bool shouldRenderGlasses(double intelligence) {
    return intelligence >= 1.7;
  }

  static double nextThornInvincibilityRemaining({
    required double current,
    required double dt,
  }) {
    return (current - dt).clamp(0.0, PhysicsTuning.thornInvincibilitySeconds);
  }

  static bool shouldUseThornFlickerLowOpacity({
    required double thornInvincibilityRemaining,
    required double thornFlickerElapsed,
  }) {
    if (thornInvincibilityRemaining <= 0) {
      return false;
    }
    return (thornFlickerElapsed / PhysicsTuning.thornFlickerStepSeconds)
        .floor()
        .isEven;
  }

  static Vector2 resolveThornKnockbackDirection({
    required Vector2 playerCenter,
    required Vector2 collisionMidpoint,
    Vector2? thornCenter,
  }) {
    final Vector2 collisionNormal = playerCenter - collisionMidpoint;
    if (collisionNormal.length2 == 0 && thornCenter != null) {
      collisionNormal.setFrom(playerCenter - thornCenter);
    }
    if (collisionNormal.length2 == 0) {
      collisionNormal.setValues(0, -1);
    }
    collisionNormal.normalize();
    return collisionNormal;
  }

  static PlayerVerticalPosition resolveVerticalPosition({
    required PlayerVerticalPosition current,
    required bool isInWater,
    required bool jumpPressed,
    required bool divePressed,
    required bool canStayOnLand,
    required bool jumpActive,
  }) {
    if (jumpActive) {
      return PlayerVerticalPosition.land;
    }
    if (current == PlayerVerticalPosition.land) {
      if (isInWater && !canStayOnLand) {
        return PlayerVerticalPosition.waterLevel;
      }
      return PlayerVerticalPosition.land;
    }

    if (current == PlayerVerticalPosition.waterLevel) {
      if (divePressed && isInWater) {
        return PlayerVerticalPosition.underwater;
      }
      return PlayerVerticalPosition.waterLevel;
    }

    if (!isInWater) {
      return PlayerVerticalPosition.waterLevel;
    }

    if (jumpPressed) {
      return PlayerVerticalPosition.waterLevel;
    }
    return PlayerVerticalPosition.underwater;
  }

  void _startJump() {
    if (_jumpActive) {
      return;
    }
    _jumpActive = true;
    _jumpElapsed = 0;
    _jumpDirection = Vector2(sin(angle), -cos(angle));
    if (_jumpDirection.length2 == 0) {
      _jumpDirection = Vector2(0, -1);
    }
    _jumpDirection.normalize();
    inputState.playerVerticalPosition = PlayerVerticalPosition.land;
  }

  void _resolveJump(double dt) {
    if (!_jumpActive) {
      return;
    }

    _jumpElapsed += dt;
    final double t = (_jumpElapsed / PhysicsTuning.jumpDurationSeconds).clamp(
      0,
      1,
    );
    final double forwardScale = (1 - (PhysicsTuning.jumpForwardScaleDecay * t))
        .clamp(PhysicsTuning.minJumpForwardScale, 1.0);
    position +=
        _jumpDirection * PhysicsTuning.jumpForwardSpeed * dt * forwardScale;

    if (_jumpElapsed >= PhysicsTuning.jumpDurationSeconds) {
      _jumpActive = false;
      _jumpElapsed = 0;
      inputState.playerVerticalPosition =
          (_isTouchingGround || _isTouchingLily || _isTouchingFrogHouse)
          ? PlayerVerticalPosition.land
          : PlayerVerticalPosition.waterLevel;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isInWater) {
      _underwaterSurfaceGraceRemaining =
          PhysicsTuning.underwaterSurfaceGraceSeconds;
    } else {
      _underwaterSurfaceGraceRemaining = (_underwaterSurfaceGraceRemaining - dt)
          .clamp(0.0, PhysicsTuning.underwaterSurfaceGraceSeconds);
    }
    _thornInvincibilityRemaining = nextThornInvincibilityRemaining(
      current: _thornInvincibilityRemaining,
      dt: dt,
    );
    _thornFlickerElapsed += dt;

    if (game.phase.value != GamePhase.playing) {
      return;
    }

    if (_isMoving) {
      if (!_wasMoving || previousPosition != levelPosition) {
        animation = moveAnimation(levelPosition);
      }
    } else {
      if (_wasMoving || previousPosition != levelPosition) {
        animation = idleAnimation(levelPosition);
      }
    }
    previousPosition = levelPosition;

    if (_isMoving) {
      if (!_wasMoving || previousPosition != levelPosition) {
        animation = moveAnimation(levelPosition);
      }
    } else {
      if (_wasMoving || previousPosition != levelPosition) {
        animation = idleAnimation(levelPosition);
      }
    }
    previousPosition = levelPosition;

    if (!isInWater && _isMoving) {
      _hopTime += dt;
    } else {
      _hopTime = 0.0;
    }
    final double hopScale = isInWater ? 1.0 : sin(_hopTime * 8.0).abs();

    position +=
        velocity *
        PhysicsTuning.playerMoveSpeed *
        _speedMultiplier *
        dt *
        (hopScale * 1.5);
    position += _thornKnockbackVelocity * dt;
    _thornKnockbackVelocity.scale(
      (1 - (PhysicsTuning.thornKnockbackDrag * dt)).clamp(0.0, 1.0),
    );
    if (_thornKnockbackVelocity.length2 <=
        PhysicsTuning.thornKnockbackMinSpeed *
            PhysicsTuning.thornKnockbackMinSpeed) {
      _thornKnockbackVelocity.setZero();
    }
    _wasMoving = _isMoving;

    final double targetAngle = velocity.screenAngle();
    if (velocity.x != 0 || velocity.y != 0) {
      final double angleDelta = _shortestAngleDelta(targetAngle, angle);
      if (angleDelta != 0) {
        final double maxStep =
            PhysicsTuning.playerRotationSpeed * _speedMultiplier * dt;
        final double step = angleDelta.clamp(-maxStep, maxStep).toDouble();
        angle = _normalizeAngle(angle + step);
      }
    }

    if (inputState.jumpPressed &&
        levelPosition == PlayerVerticalPosition.waterLevel &&
        isInWater) {
      _startJump();
    }
    _resolveJump(dt);

    final double maxX = GameConfig.worldSize.x - size.x;
    final double maxY = GameConfig.worldSize.y - size.y;
    position.y = position.y.clamp(0, maxY);
    position.x = position.x.clamp(0, maxX);

    bool effectiveInWater = isInWater;
    if (!effectiveInWater &&
        levelPosition == PlayerVerticalPosition.underwater) {
      effectiveInWater = game.level.isPositionInWater(absoluteCenter);
    }

    inputState.playerVerticalPosition = resolveVerticalPosition(
      current: levelPosition,
      isInWater:
          effectiveInWater ||
          (levelPosition == PlayerVerticalPosition.underwater &&
              _underwaterSurfaceGraceRemaining > 0),
      jumpPressed: inputState.jumpPressed,
      divePressed: inputState.divePressed,
      canStayOnLand:
          _isTouchingGround || _isTouchingLily || _isTouchingFrogHouse,
      jumpActive: _jumpActive,
    );

    switch (levelPosition) {
      case PlayerVerticalPosition.land:
        _spriteOpacity = PhysicsTuning.landOpacity;
        priority = 110;
        size = Vector2.all(
          PhysicsTuning.playerBaseSize * _sizeMultiplier * 1.1,
        );
        break;
      case PlayerVerticalPosition.waterLevel:
        _spriteOpacity = PhysicsTuning.waterOpacity;
        priority = 110;
        size = Vector2.all(PhysicsTuning.playerBaseSize * _sizeMultiplier);
        break;
      case PlayerVerticalPosition.underwater:
        _spriteOpacity = PhysicsTuning.underwaterOpacity;
        priority = 50;
        size = Vector2.all(
          PhysicsTuning.playerBaseSize * _sizeMultiplier * 0.9,
        );
        break;
    }
    final bool isFlickerLow = shouldUseThornFlickerLowOpacity(
      thornInvincibilityRemaining: _thornInvincibilityRemaining,
      thornFlickerElapsed: _thornFlickerElapsed,
    );
    final double targetOpacity = isFlickerLow
        ? PhysicsTuning.thornFlickerLowOpacity
        : _spriteOpacity;
    paint.color = Colors.white.withValues(alpha: targetOpacity);
    _syncHitbox();
  }

  void reset() {
    position.setFrom(_startPosition);
    _remainingHealth = _maxHealth;
    _thornKnockbackVelocity.setZero();
    _thornInvincibilityRemaining = 0;
    _thornFlickerElapsed = 0;
    _waterContacts = 0;
    _groundContacts = 0;
    _lilyContacts = 0;
    isInWater = false;
    _jumpActive = false;
    _jumpElapsed = 0;
    _underwaterSurfaceGraceRemaining = 0;
    _hopTime = 0;
    // Reset the vertical position to land, matching the spawn tile.
    inputState.playerVerticalPosition = PlayerVerticalPosition.land;
    previousPosition = PlayerVerticalPosition.land;
  }

  Future<void> onHitGround(GroundComponent ground) async {
    if (game.phase.value != GamePhase.playing) {
      return;
    }
    if (_isDamageTextVisible) return;
    Future.delayed(_damageTextDelay, () {
      _isDamageTextVisible = false;
    });
    _isDamageTextVisible = true;
    applyDamage(ground.damage);
    final damageText = SimpleTextComponent(
      color: Colors.red,
      text: '- ${ground.damage}',
      position: Vector2(size.x, -24),
      priority: 50,
    );
    await damageText.add(
      MoveEffect.by(
        Vector2(
          game.random.nextDouble() * size.x,
          game.random.nextDouble() * size.y,
        ),
        EffectController(duration: 1.0, curve: Curves.linear, repeatCount: 1),
      ),
    );
    add(damageText);
    Future.delayed(_damageTextDuration, () {
      if (damageText.parent == null) return;
      damageText.removeFromParent();
    });
  }

  Vector2 _resolveCollisionMidpoint(Set<Vector2> intersectionPoints) {
    if (intersectionPoints.isEmpty) {
      return absoluteCenter.clone();
    }
    Vector2 sum = Vector2.zero();
    for (final Vector2 point in intersectionPoints) {
      sum += point;
    }
    return sum / intersectionPoints.length.toDouble();
  }

  void _applyThornImpact(
    Set<Vector2> intersectionPoints,
    ThornComponent thorn,
  ) {
    final Vector2 collisionMid = _resolveCollisionMidpoint(intersectionPoints);
    final Vector2 collisionNormal = resolveThornKnockbackDirection(
      playerCenter: absoluteCenter,
      collisionMidpoint: collisionMid,
      thornCenter: thorn.absoluteCenter,
    );
    _thornKnockbackVelocity.setFrom(
      collisionNormal.scaled(PhysicsTuning.thornKnockbackSpeed),
    );

    final double separationDistance =
        (size.x / 2) - absoluteCenter.distanceTo(collisionMid);
    if (separationDistance > 0) {
      position += collisionNormal.scaled(separationDistance);
    }
  }

  Future<void> runDamageFlashEffect() async {
    await add(
      SequenceEffect([
        OpacityEffect.to(
          PhysicsTuning.thornFlickerLowOpacity,
          EffectController(duration: PhysicsTuning.thornFlashStepSeconds),
        ),
        OpacityEffect.to(
          1,
          EffectController(duration: PhysicsTuning.thornFlashStepSeconds),
        ),
      ]),
    );
  }

  Future<void> _spawnThornParticles(Vector2 impactPoint) async {
    final Paint particlePaint = Paint()
      ..color = Colors.lightGreenAccent.withValues(
        alpha: PhysicsTuning.thornParticleAlpha,
      );
    await game.world.add(
      ParticleSystemComponent(
        position: impactPoint,
        priority: priority + 1,
        particle: Particle.generate(
          count: PhysicsTuning.thornParticleCount,
          lifespan: PhysicsTuning.thornParticleLifespanSeconds,
          generator: (int index) {
            final double direction = game.random.nextDouble() * pi * 2;
            final double speed =
                PhysicsTuning.thornParticleSpeedMin +
                game.random.nextDouble() *
                    (PhysicsTuning.thornParticleSpeedMax -
                        PhysicsTuning.thornParticleSpeedMin);
            return AcceleratedParticle(
              speed: Vector2(cos(direction), sin(direction)) * speed,
              child: CircleParticle(
                radius: PhysicsTuning.thornParticleRadius,
                paint: particlePaint,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onThornCollision(
    Set<Vector2> intersectionPoints,
    ThornComponent thorn,
  ) async {
    _applyThornImpact(intersectionPoints, thorn);
    if (_thornInvincibilityRemaining > 0) {
      return;
    }
    _thornInvincibilityRemaining = PhysicsTuning.thornInvincibilitySeconds;
    _thornFlickerElapsed = 0;
    applyDamage(PhysicsTuning.thornDamageAmount);
    await runDamageFlashEffect();
    await _spawnThornParticles(_resolveCollisionMidpoint(intersectionPoints));
  }

  @override
  Future<void> onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) async {
    if (game.phase.value != GamePhase.playing) {
      super.onCollision(intersectionPoints, other);
      return;
    }
    if (other is GroundComponent) {
      await onHitGround(other);
      if (levelPosition != PlayerVerticalPosition.land && !_jumpActive) {
        if (intersectionPoints.length == 2) {
          final mid =
              (intersectionPoints.elementAt(0) +
                  intersectionPoints.elementAt(1)) /
              2;
          final collisionNormal = absoluteCenter - mid;
          final separationDistance = (size.x / 2) - collisionNormal.length;
          collisionNormal.normalize();
          final double moveDot = velocity.dot(collisionNormal);
          if (moveDot < 0 || separationDistance > 1.5) {
            position += collisionNormal.scaled(separationDistance);
          }
        }
      }
    }
    if (other is ThornComponent) {
      await _onThornCollision(intersectionPoints, other);
    }
    if (other is WaterLilyComponent &&
        levelPosition == PlayerVerticalPosition.waterLevel) {
      if (intersectionPoints.length != 2) return;
      final mid =
          (intersectionPoints.elementAt(0) + intersectionPoints.elementAt(1)) /
          2;
      final collisionNormal = absoluteCenter - mid;
      final separationDistance = (size.x / 2) - collisionNormal.length;
      collisionNormal.normalize();
      position += collisionNormal.scaled(separationDistance);
    }
    if (other is FrogHouseComponent) {
      if (levelPosition != PlayerVerticalPosition.land && !_jumpActive) {
        if (intersectionPoints.length == 2) {
          final mid =
              (intersectionPoints.elementAt(0) +
                  intersectionPoints.elementAt(1)) /
              2;
          final collisionNormal = absoluteCenter - mid;
          final separationDistance = (size.x / 2) - collisionNormal.length;
          collisionNormal.normalize();
          final double moveDot = velocity.dot(collisionNormal);
          if (moveDot < 0 || separationDistance > 1.5) {
            position += collisionNormal.scaled(separationDistance);
          }
        }
      }
    }

    if (other is EggComponent) {
      eggsCollected++;
      debugPrint('Collected an egg!');
      await other.collect();
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is WaterComponent) {
      _waterContacts++;
      isInWater = _waterContacts > 0;
      if (isInWater) {
        _underwaterSurfaceGraceRemaining =
            PhysicsTuning.underwaterSurfaceGraceSeconds;
      }
      if (isInWater) {
        removeAll(children.whereType<SimpleTextComponent>());
      }
    }
    if (other is FrogHouseComponent) {
      _frogHouseContacts++;
      if (_jumpActive) {
        _jumpActive = false;
        _jumpElapsed = 0;
        inputState.playerVerticalPosition = PlayerVerticalPosition.land;
      }
      super.onCollisionStart(intersectionPoints, other);
      return;
    }
    if (other is GroundComponent) {
      _groundContacts++;
      if (_jumpActive) {
        _jumpActive = false;
        _jumpElapsed = 0;
        inputState.playerVerticalPosition = PlayerVerticalPosition.land;
      }
      super.onCollisionStart(intersectionPoints, other);
      return;
    }
    if (other is WaterLilyComponent) {
      _lilyContacts++;
      if (_jumpActive) {
        _jumpActive = false;
        _jumpElapsed = 0;
        inputState.playerVerticalPosition = PlayerVerticalPosition.land;
      }
      super.onCollisionStart(intersectionPoints, other);
      return;
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is GroundComponent) {
      _groundContacts = (_groundContacts - 1).clamp(0, 999999);
      removeAll(children.whereType<SimpleTextComponent>());
    }
    if (other is WaterComponent) {
      _waterContacts = (_waterContacts - 1).clamp(0, 999999);
      isInWater = _waterContacts > 0;
    }
    if (other is WaterLilyComponent) {
      _lilyContacts = (_lilyContacts - 1).clamp(0, 999999);
    }
    if (other is FrogHouseComponent) {
      _frogHouseContacts = (_frogHouseContacts - 1).clamp(0, 999999);
    }

    super.onCollisionEnd(other);
  }

  void applyDamage(int damage) {
    if (game.phase.value != GamePhase.playing) {
      return;
    }
    _remainingHealth = (_remainingHealth - damage).clamp(0, _maxHealth);
    if (_remainingHealth <= 0) {
      game.endGame();
    }
  }

  Future<void> applyDamageWithInvincibilityDelay(
    int damage,
    double delay,
  ) async {
    if (_thornInvincibilityRemaining > 0) {
      return;
    }
    _thornInvincibilityRemaining = delay;
    _thornFlickerElapsed = 0;
    applyDamage(damage);
    await runDamageFlashEffect();
  }
}
