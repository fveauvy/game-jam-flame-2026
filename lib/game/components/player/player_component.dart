import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
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
    with HasGameReference<MyGame>, CollisionCallbacks {
  PlayerComponent({
    required this.inputState,
    required CharacterProfile profile,
    required Vector2 startPosition,
    double speedMultiplier = 1.0,
    double sizeMultiplier = 1.0,
    double intelligence = 1.0,
  }) : _startPosition = startPosition.clone(),
       _profile = profile,
       _baseSpeedMultiplier = speedMultiplier,
       _baseSizeMultiplier = sizeMultiplier,
       _intelligence = intelligence,
       super(
         position: startPosition.clone(),
         radius: 48,
         anchor: Anchor.center,
         priority: 10,
         paint: Paint()..color = _parseColor(profile.colorHex),
       ) {
    _applyStatsFromProfile();
  }

  static const Duration _damageTextDuration = Duration(seconds: 1);
  static const Duration _damageTextDelay = Duration(milliseconds: 500);

  final InputState inputState;
  final Vector2 _startPosition;
  final double _baseSpeedMultiplier;
  final double _baseSizeMultiplier;

  CharacterProfile _profile;
  late double _speedMultiplier;
  late double _sizeMultiplier;
  final double _intelligence;

  static const double _moveSpeed = 340;
  static const double _rotationSpeed = 30;

  PlayerType get levelPosition => inputState.playerType;
  double get moveSpeed => _moveSpeed;

  CharacterProfile get profile => _profile;

  late Paint _directionDotPaint;

  bool _isDamageTextVisible = false;
  bool get _isInWater =>
      levelPosition == PlayerType.middle || levelPosition == PlayerType.water;

  @override
  Future<void> onMount() async {
    super.onMount();
    _directionDotPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    await add(CircleHitbox(radius: radius));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final double dotRadius = radius * 0.15 * _intelligence;
    final double dotOffset = radius * 0.5;
    final double topY = dotRadius;

    canvas.drawCircle(Offset(dotOffset, topY), dotRadius, _directionDotPaint);
    canvas.drawCircle(
      Offset(dotOffset + radius, topY),
      dotRadius,
      _directionDotPaint,
    );
  }

  static Color _parseColor(String hex) {
    final String normalized = hex.replaceFirst('#', '').trim();
    if (normalized.length != 6) {
      return const Color(0xFF2A9D8F);
    }
    final int? rgb = int.tryParse(normalized, radix: 16);
    if (rgb == null) {
      return const Color(0xFF2A9D8F);
    }
    return Color(0xFF000000 | rgb);
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
    paint.color = _parseColor(profile.colorHex);
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
    radius = 48 * _sizeMultiplier;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.phase.value != GamePhase.playing) {
      return;
    }

    final Vector2 velocity = Vector2(
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

    Color newColor = _parseColor(profile.colorHex);
    switch (levelPosition) {
      case PlayerType.land:
        newColor = newColor.withValues(alpha: 1.0);
        radius = 48 * _sizeMultiplier * 1.1;
        break;
      case PlayerType.middle:
        newColor = newColor.withValues(alpha: 0.7);
        radius = 48 * _sizeMultiplier;
        break;
      case PlayerType.water:
        newColor = newColor.withValues(alpha: 0.4);
        radius = 48 * _sizeMultiplier * 0.9;
        break;
    }
    paint = Paint()..color = newColor;
  }

  void reset() {
    position.setFrom(_startPosition);
  }

  Future<void> onHitGround(GroundComponent ground) async {
    if (_isDamageTextVisible) return;
    Future.delayed(_damageTextDelay, () {
      _isDamageTextVisible = false;
    });
    _isDamageTextVisible = true;
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
