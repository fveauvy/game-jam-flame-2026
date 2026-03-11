import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/game/components/player/player_component.dart';

class WaterRippleComponent extends PositionComponent {
  // On le met en PositionComponent pour qu'il soit un élément du World.
  // Priorité entre le terrain (0) et le joueur (10).
  WaterRippleComponent({required this.player}) : super(priority: 5);

  final PlayerComponent player;
  bool isActive = false;
  final List<_Ripple> _ripples = [];
  double _timeSinceLastSpawn = 0;

  static const double _spawnInterval = 2;
  static const int _ringsPerSet = 1;
  static const double _growSpeed = 60.0;
  static const double _fadeSpeed = 1.5;
  static const double _strokeWidth = 3;
  static const Color _rippleColor = Color.fromARGB(255, 189, 225, 255);
  static const Color _rippleColorEnd = Color.fromARGB(97, 8, 0, 59);

  @override
  void update(double dt) {
    // Mise à jour de l'état depuis le joueur
    isActive = player.isInWater;

    for (final r in _ripples) {
      r.radius += _growSpeed * dt;
      r.alpha -= _fadeSpeed * dt;
    }
    _ripples.removeWhere((r) => r.alpha <= 0);

    if (isActive) {
      final speed = player.velocity.length;

      final spawnInterval = _spawnInterval - (speed * 1.9);

      _timeSinceLastSpawn += dt;
      if (_timeSinceLastSpawn >= spawnInterval) {
        _timeSinceLastSpawn = 0;
        _spawnRippleSet();
      }
    }
    super.update(dt);
  }

  void _spawnRippleSet() {
    final faceX = sin(player.angle);
    final faceY = -cos(player.angle);
    final backOffset = player.size.x * 0.6 * player.velocity.length;

    // Position mondiale directe (pas besoin de conversion locale)
    final spawnPos = Vector2(
      player.position.x - faceX * backOffset,
      player.position.y - faceY * backOffset,
    );

    for (int i = 0; i < _ringsPerSet; i++) {
      _ripples.add(
        _Ripple(radius: player.size.x * 0.5, alpha: 0.85, position: spawnPos),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    if (_ripples.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    for (final ripple in _ripples) {
      final alpha = ripple.alpha.clamp(0.0, 1.0);
      paint.color =
          Color.lerp(_rippleColor, _rippleColorEnd, 1 - alpha) ?? _rippleColor;
      paint.blendMode = BlendMode.screen;
      // On dessine directement aux coordonnées mondiales car on est un composant du World
      canvas.drawCircle(ripple.position.toOffset(), ripple.radius, paint);
    }
  }
}

class _Ripple {
  _Ripple({required this.radius, required this.alpha, required this.position});
  Vector2 position;
  double radius;
  double alpha;
}
