import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/entities/player_type.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/components/environment/ground_component.dart';
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
         radius: 48,
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

  static const double _moveSpeed = 340;
  static const double _rotationSpeed = 30;

  PlayerType get levelPosition => inputState.playerType;
  double get moveSpeed => _moveSpeed;

  CharacterProfile get profile => _profile;
  int get maxHealth => _maxHealth;
  int get remainingHealth => _remainingHealth;

  bool _isDamageTextVisible = false;
  bool get _isInWater =>
      levelPosition == PlayerType.middle || levelPosition == PlayerType.water;

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
      0.2,
      5.0,
    );
    _sizeMultiplier = (_profile.traits.size ?? _baseSizeMultiplier).clamp(
      0.3,
      3.0,
    );
    _maxHealth = resolveMaxHealth(_profile);
    _remainingHealth = _maxHealth;
    radius = 48 * _sizeMultiplier;
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
    const String prefix = 'assets/images/';
    if (path.startsWith(prefix)) {
      return path.substring(prefix.length);
    }
    return path;
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

  @override
  void update(double dt) {
    super.update(dt);
    if (game.phase.value != GamePhase.playing) {
      return;
    }

    final Vector2 velocity = normalizeMoveAxis(
      inputState.moveAxisX,
      inputState.moveAxisY,
    );
    position += velocity * _moveSpeed * _speedMultiplier * dt;

    final double targetAngle = velocity.screenAngle();
    if (velocity.x != 0 || velocity.y != 0) {
      final double angleDelta = _shortestAngleDelta(targetAngle, angle);
      if (angleDelta != 0) {
        final double maxStep = _rotationSpeed * _speedMultiplier * dt;
        final double step = angleDelta.clamp(-maxStep, maxStep).toDouble();
        angle = _normalizeAngle(angle + step);
      }
    }

    final double maxX = GameConfig.worldSize.x - size.x;
    final double maxY = GameConfig.worldSize.y - size.y;
    position.y = position.y.clamp(0, maxY);
    position.x = position.x.clamp(0, maxX);

    switch (levelPosition) {
      case PlayerType.land:
        _spriteOpacity = 1.0;
        radius = 48 * _sizeMultiplier * 1.1;
        break;
      case PlayerType.middle:
        _spriteOpacity = 0.7;
        radius = 48 * _sizeMultiplier;
        break;
      case PlayerType.water:
        _spriteOpacity = 0.4;
        radius = 48 * _sizeMultiplier * 0.9;
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
    if (other is GroundComponent && !_isInWater) await onHitGround(other);

    if (other is WaterLilyComponent && levelPosition == PlayerType.middle) {
      if (intersectionPoints.length != 2) return;
      final mid =
          (intersectionPoints.elementAt(0) + intersectionPoints.elementAt(1)) /
          2;
      final collisionNormal = absoluteCenter - mid;
      final separationDistance = (size.x / 2) - collisionNormal.length;
      collisionNormal.normalize();
      position += collisionNormal.scaled(separationDistance);
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is GroundComponent) {
      removeAll(children.whereType<SimpleTextComponent>());
    }

    super.onCollisionEnd(other);
  }
}
