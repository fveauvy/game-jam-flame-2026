import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/input/input_state.dart';
import 'package:game_jam/game/my_game.dart';

class PlayerComponent extends CircleComponent with HasGameReference<MyGame> {
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

  final InputState inputState;
  final Vector2 _startPosition;
  final double _baseSpeedMultiplier;
  final double _baseSizeMultiplier;

  CharacterProfile _profile;
  late double _speedMultiplier;
  late double _sizeMultiplier;
  double _intelligence;

  static const double _moveSpeed = 340;
  static const double _rotationSpeed = 30;

  CharacterProfile get profile => _profile;

  late Paint _directionDotPaint;

  @override
  void onMount() {
    super.onMount();
    _directionDotPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
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
    if (targetAngle != angle && (velocity.x != 0 || velocity.y != 0)) {
      final double angleNeeded = targetAngle - angle;
      final bool clockwise = angleNeeded > 0;
      if (clockwise) {
        angle += min(angleNeeded, _rotationSpeed * _speedMultiplier * dt);
      } else {
        angle -= min(-angleNeeded, _rotationSpeed * _speedMultiplier * dt);
      }
    }

    final double maxX = GameConfig.worldSize.x - size.x;
    final double maxY = GameConfig.worldSize.y - size.y;
    position.y = position.y.clamp(0, maxY);
    position.x = position.x.clamp(0, maxX);
  }

  void reset() {
    position.setFrom(_startPosition);
  }
}
