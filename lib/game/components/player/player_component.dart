import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/constants/asset_paths.dart';
import 'package:game_jam/core/constants/physics.dart';
import 'package:game_jam/core/entities/player_vertical_position.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/components/allies/tadpole.dart';
import 'package:game_jam/game/components/environment/ground_component.dart';
import 'package:game_jam/game/components/environment/water_component.dart';
import 'package:game_jam/game/components/environment/water_lily_component.dart';
import 'package:game_jam/game/components/text/simple_text_component.dart';
import 'package:game_jam/game/input/input_state.dart';
import 'package:game_jam/game/my_game.dart';

class PlayerComponent extends CircleComponent
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
         radius: PhysicsTuning.playerBaseRadius,
         anchor: Anchor.center,
         priority: 10,
         paint: Paint()..color = Colors.transparent,
       ) {
    _applyStatsFromProfile();
  }

  static const Duration _damageTextDuration = Duration(seconds: 1);
  static const Duration _damageTextDelay = Duration(milliseconds: 500);
  static const int _defaultHealth = 100;

  final InputState inputState;
  final Vector2 _startPosition;
  final double _baseSpeedMultiplier;
  final double _baseSizeMultiplier;

  CharacterProfile _profile;
  Sprite? _frogSprite;
  late String _spriteCacheKey;
  late final Paint _spritePaint;
  double _spriteOpacity = 1.0;
  CircleHitbox? _hitbox;
  late double _speedMultiplier;
  late double _sizeMultiplier;
  late int _maxHealth;
  late int _remainingHealth;

  PlayerVerticalPosition get levelPosition => inputState.playerVerticalPosition;
  double get moveSpeed => PhysicsTuning.playerMoveSpeed;

  CharacterProfile get profile => _profile;
  int get maxHealth => _maxHealth;
  int get remainingHealth => _remainingHealth;

  bool _isDamageTextVisible = false;
  bool isInWater = false;
  int _waterContacts = 0;
  int _groundContacts = 0;
  int _lilyContacts = 0;
  bool _jumpActive = false;
  double _jumpElapsed = 0;
  Vector2 _jumpDirection = Vector2.zero();

  bool get _isTouchingGround => _groundContacts > 0;
  bool get _isTouchingLily => _lilyContacts > 0;

  Vector2 get velocity =>
      normalizeMoveAxis(inputState.moveAxisX, inputState.moveAxisY);

  @override
  void onTapDown(TapDownEvent event) {
    game.startGame();
    super.onTapDown(event);
  }

  @override
  Future<void> onMount() async {
    super.onMount();
    _spritePaint = Paint();
    _refreshSprite();
    _hitbox = CircleHitbox(radius: radius);
    await add(_hitbox!);
  }

  @override
  void render(Canvas canvas) {
    if (_frogSprite == null) {
      super.render(canvas);
      return;
    }
    _frogSprite!.render(canvas, size: size, overridePaint: _spritePaint);
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
    _refreshSprite();
    _applyStatsFromProfile();
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
    radius = PhysicsTuning.playerBaseRadius * _sizeMultiplier;
    _syncHitbox();
  }

  void _refreshSprite() {
    _spriteCacheKey = _cacheKeyFromAssetPath(_profile.spriteAssetPath);
    if (!game.images.containsKey(_spriteCacheKey)) {
      _frogSprite = null;
      return;
    }
    _frogSprite = Sprite(game.images.fromCache(_spriteCacheKey));
  }

  String _cacheKeyFromAssetPath(String path) {
    return AssetPaths.imageCacheKeyFromAssetPath(path);
  }

  void _syncHitbox() {
    final CircleHitbox? hitbox = _hitbox;
    if (hitbox == null) {
      return;
    }
    hitbox.radius = radius;
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
      inputState.playerVerticalPosition = (_isTouchingGround || _isTouchingLily)
          ? PlayerVerticalPosition.land
          : PlayerVerticalPosition.waterLevel;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.phase.value != GamePhase.playing) {
      return;
    }

    position +=
        velocity * PhysicsTuning.playerMoveSpeed * _speedMultiplier * dt;

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

    inputState.playerVerticalPosition = resolveVerticalPosition(
      current: levelPosition,
      isInWater: isInWater,
      jumpPressed: inputState.jumpPressed,
      divePressed: inputState.divePressed,
      canStayOnLand: _isTouchingGround || _isTouchingLily,
      jumpActive: _jumpActive,
    );

    switch (levelPosition) {
      case PlayerVerticalPosition.land:
        _spriteOpacity = PhysicsTuning.landOpacity;
        radius = PhysicsTuning.playerBaseRadius * _sizeMultiplier * 1.1;
        break;
      case PlayerVerticalPosition.waterLevel:
        _spriteOpacity = PhysicsTuning.waterOpacity;
        radius = PhysicsTuning.playerBaseRadius * _sizeMultiplier;
        break;
      case PlayerVerticalPosition.underwater:
        _spriteOpacity = PhysicsTuning.underwaterOpacity;
        radius = PhysicsTuning.playerBaseRadius * _sizeMultiplier * 0.9;
        break;
    }
    _spritePaint.color = Colors.white.withValues(alpha: _spriteOpacity);
    _syncHitbox();
  }

  void reset() {
    position.setFrom(_startPosition);
    _remainingHealth = _maxHealth;
  }

  Future<void> onHitGround(GroundComponent ground) async {
    if (_isDamageTextVisible) return;
    Future.delayed(_damageTextDelay, () {
      _isDamageTextVisible = false;
    });
    _isDamageTextVisible = true;
    _remainingHealth = (_remainingHealth - ground.damage).clamp(0, _maxHealth);
    if (_remainingHealth <= 0) {
      game.endGame();
    }
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

  @override
  Future<void> onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) async {
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

    if (other is Egg) {
      debugPrint('Collected an egg!');
      other.collect();
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
        removeAll(children.whereType<SimpleTextComponent>());
      }
    }
    if (other is GroundComponent) {
      _groundContacts++;
      if (_jumpActive) {
        _jumpActive = false;
        _jumpElapsed = 0;
        inputState.playerVerticalPosition = PlayerVerticalPosition.land;
      }
    }
    if (other is WaterLilyComponent) {
      _lilyContacts++;
      if (_jumpActive) {
        _jumpActive = false;
        _jumpElapsed = 0;
        inputState.playerVerticalPosition = PlayerVerticalPosition.land;
      }
    }
    super.onCollisionStart(intersectionPoints, other);
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

    super.onCollisionEnd(other);
  }
}
