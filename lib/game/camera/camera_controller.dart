import 'dart:math';

import 'package:flame/components.dart';

class GameCameraController {
  GameCameraController({
    required this.camera,
    required PositionComponent target,
    required this.worldSize,
    required this.viewportSize,
  }) : _target = target;

  final CameraComponent camera;
  PositionComponent _target;
  final Vector2 worldSize;
  final Vector2 viewportSize;

  /// The current object the camera follows.
  PositionComponent get target => _target;
  set target(PositionComponent t) => _target = t;

  void attach() {
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  void update() {
    final double maxX = max(0, worldSize.x - viewportSize.x);
    final double maxY = max(0, worldSize.y - viewportSize.y);

    final double nextX = (_target.position.x - viewportSize.x * 0.35).clamp(
      0,
      maxX,
    );
    final double nextY = (_target.position.y - viewportSize.y * 0.6).clamp(
      0,
      maxY,
    );

    camera.viewfinder.position = Vector2(nextX, nextY);
  }
}
