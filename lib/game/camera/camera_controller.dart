import 'dart:math';

import 'package:flame/components.dart';

class GameCameraController {
  GameCameraController({
    required this.camera,
    required this.target,
    required this.worldSize,
    required this.viewportSize,
  });

  final CameraComponent camera;
  final PositionComponent target;
  final Vector2 worldSize;
  final Vector2 viewportSize;

  void attach() {
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  void update() {
    final double maxX = max(0, worldSize.x - viewportSize.x);
    final double maxY = max(0, worldSize.y - viewportSize.y);

    final double nextX = (target.position.x - viewportSize.x * 0.35).clamp(
      0,
      maxX,
    );
    final double nextY = (target.position.y - viewportSize.y * 0.6).clamp(
      0,
      maxY,
    );

    camera.viewfinder.position = Vector2(nextX, nextY);
  }
}
