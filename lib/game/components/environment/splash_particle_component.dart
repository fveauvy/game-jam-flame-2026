import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/physics_tuning.dart';

class SplashParticleComponent extends PositionComponent {
  SplashParticleComponent({
    required Vector2 position,
    int? priority,
    Random? random,
    double scale = 1.0,
  }) : _random = random ?? Random(),
       _scale = scale,
       super(position: position, priority: priority ?? 10);

  final Random _random;
  final double _scale;

  final List<_SplashParticle> _particles = [];
  bool _spawned = false;

  @override
  void onMount() {
    super.onMount();
    _spawnParticles();
  }

  void _spawnParticles() {
    if (_spawned) return;
    _spawned = true;

    for (int i = 0; i < PhysicsTuning.splashDropletCount; i++) {
      final angle = _randomDropletAngle();
      final speed =
          PhysicsTuning.splashDropletSpeedMin +
          _random.nextDouble() *
              (PhysicsTuning.splashDropletSpeedMax -
                  PhysicsTuning.splashDropletSpeedMin);
      final radius =
          (PhysicsTuning.splashDropletRadiusMin +
              _random.nextDouble() *
                  (PhysicsTuning.splashDropletRadiusMax -
                      PhysicsTuning.splashDropletRadiusMin)) *
          _scale;

      _particles.add(
        _SplashParticle(
          velocity: Vector2(cos(angle), sin(angle)) * speed * _scale,
          gravity: PhysicsTuning.splashGravity * _scale,
          radius: radius,
          lifespan: PhysicsTuning.splashDropletLifespanSeconds,
          colorStart: PhysicsTuning.splashDropletColorStart,
          colorEnd: PhysicsTuning.splashDropletColorEnd,
        ),
      );
    }

    for (int i = 0; i < PhysicsTuning.splashRingCount; i++) {
      final spreadAngle = (i / PhysicsTuning.splashRingCount) * pi * 2;
      final speed =
          PhysicsTuning.splashRingSpeedMin +
          _random.nextDouble() *
              (PhysicsTuning.splashRingSpeedMax -
                  PhysicsTuning.splashRingSpeedMin);
      _particles.add(
        _SplashParticle(
          velocity:
              Vector2(cos(spreadAngle), sin(spreadAngle)) * speed * _scale,
          gravity: 0,
          radius:
              PhysicsTuning.splashRingParticleRadius *
              _scale *
              (0.7 + _random.nextDouble() * 0.6),
          lifespan: PhysicsTuning.splashRingLifespanSeconds,
          colorStart: PhysicsTuning.splashRingColorStart,
          colorEnd: PhysicsTuning.splashRingColorEnd,
        ),
      );
    }
  }

  double _randomDropletAngle() {
    final spread = PhysicsTuning.splashDropletAngleSpreadDegrees * (pi / 180);
    final center = -pi / 2; // straight up
    return center + ((_random.nextDouble() * 2) - 1) * spread / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final p in _particles) {
      p.update(dt);
    }
    _particles.removeWhere((p) => p.isDead);

    if (_spawned && _particles.isEmpty) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      final t = 1.0 - (p.remainingLifespan / p.lifespan).clamp(0.0, 1.0);
      paint.color = Color.lerp(p.colorStart, p.colorEnd, t) ?? p.colorStart;
      canvas.drawCircle(p.position.toOffset(), p.radius, paint);
    }
  }
}

class _SplashParticle {
  _SplashParticle({
    required this.velocity,
    required this.gravity,
    required this.radius,
    required this.lifespan,
    required this.colorStart,
    required this.colorEnd,
  }) : remainingLifespan = lifespan;

  Vector2 velocity;
  final double gravity;
  final double radius;
  final double lifespan;
  double remainingLifespan;
  final Color colorStart;
  final Color colorEnd;

  final Vector2 position = Vector2.zero();

  bool get isDead => remainingLifespan <= 0;

  void update(double dt) {
    velocity.y += gravity * dt;
    position.addScaled(velocity, dt);
    remainingLifespan -= dt;
  }
}
