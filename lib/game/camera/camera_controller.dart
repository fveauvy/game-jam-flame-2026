import 'dart:math';

import 'package:flame/components.dart';

class GameCameraController {
  GameCameraController({
    required PositionComponent target,
    required this.viewportSize,
    required this.worldSize,
    required this.camera,
  }) : _target = target;

  final CameraComponent camera;
  final Vector2 viewportSize;
  PositionComponent _target;
  final Vector2 worldSize;

  /// The current object the camera follows.
  set target(PositionComponent t) => _target = t;

  void attach() {
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  void update() {
    final double maxX = max(0, worldSize.x - viewportSize.x);
    final double maxY = max(0, worldSize.y - viewportSize.y);

    final double nextX = (_target.position.x - viewportSize.x * 0.5).clamp(
      0,
      maxX,
    );
    final double nextY = (_target.position.y - viewportSize.y * 0.5).clamp(
      0,
      maxY,
    );

    camera.viewfinder.position = Vector2(nextX, nextY);
  }
}
