import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/game/components/player/player_component.dart';

/// Renders animated concentric ripple rings at the player's centre whenever
/// [isActive] is true (i.e. the player is on water).
///
/// Inspired by the Flame padracing Trail example:
/// https://github.com/flame-engine/flame/blob/main/examples/games/padracing/lib/trail.dart
class WaterRippleComponent extends Component {
  WaterRippleComponent({required this.player}) : super(priority: -1);

  final PlayerComponent player;

  bool isActive = false;

  final List<_Ripple> _ripples = [];

  double _timeSinceLastSpawn = 0;

  // ── tunables ──────────────────────────────────────────────────────────────
  static const double _spawnInterval = 2; // seconds between new ripple sets
  static const int _ringsPerSet = 1; // concentric rings per spawn
  static const double _ringGap = 30.0; // pixels between consecutive rings
  static const double _growSpeed = 60.0; // px / s
  static const double _fadeSpeed = 1.5; // alpha units / s
  static const double _strokeWidth = 3;
  static const Color _rippleColor = Color(0xFF90CAF9); // light-blue water tint
  static const Color _rippleColorEnd = Color(
    0x401D192A,
  ); // darker blue at max expansion
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    // Grow & fade all existing ripples regardless of active state so they
    // finish animating even after the player leaves the water.
    for (final r in _ripples) {
      r.radius += _growSpeed * dt;
      r.alpha -= _fadeSpeed * dt;
    }
    _ripples.removeWhere((r) => r.alpha <= 0);

    final speed = player.velocity.length;

    final spawnInterval = _spawnInterval - (speed * 1.9);

    if (isActive) {
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
    final backOffset = player.radius * 0.6;

    // Position absolue dans le monde (centre du joueur + offset arrière)
    final spawnX = player.position.x - faceX * backOffset;
    final spawnY = player.position.y - faceY * backOffset;

    for (int i = 0; i < _ringsPerSet; i++) {
      _ripples.add(
        _Ripple(
          radius: player.radius * 0.5 + i * _ringGap,
          alpha: 0.85 - i * 0.18,
          position: Vector2(spawnX, spawnY),
        ),
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
      // Transforme la position mondiale en position relative au repère actuel du canvas
      // Cela annule automatiquement le déplacement et la rotation du joueur
      final localPos = player.parentToLocal(ripple.position);

      final alpha = ripple.alpha.clamp(0.0, 1.0);
      paint.color =
          Color.lerp(_rippleColor, _rippleColorEnd, 1 - alpha) ?? _rippleColor;

      canvas.drawCircle(localPos.toOffset(), ripple.radius, paint);
    }
  }
}

class _Ripple {
  _Ripple({required this.radius, required this.alpha, required this.position});

  Vector2 position;
  double radius;
  double alpha;
}
