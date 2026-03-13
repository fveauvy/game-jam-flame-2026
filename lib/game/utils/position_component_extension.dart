import 'dart:math';

import 'package:flame/components.dart';
import 'package:game_jam/core/config/game_config.dart';

const double _epsilon = 1e-3;

extension PositionComponentExtension on PositionComponent {
  bool hasPixelOutOfComponent(PositionComponent otherComponent) {
    final otherTopLeft = otherComponent.absolutePosition;
    final otherBottomLeft =
        otherComponent.absolutePosition + Vector2(0, otherComponent.size.y);
    final comonentTopLeft = absolutePosition;
    final comonentBottomLeft = absolutePosition + Vector2(0, size.y);
    final otherBottomRight =
        otherComponent.absolutePosition + otherComponent.size;
    final comonentBottomRight = absolutePosition + size;
    final otherTopRight =
        otherComponent.absolutePosition + Vector2(otherComponent.size.x, 0);
    final comonentTopRight = absolutePosition + Vector2(size.x, 0);

    return comonentBottomLeft.x < otherBottomLeft.x ||
        comonentBottomRight.x > otherBottomRight.x ||
        comonentTopLeft.y > otherTopLeft.y ||
        comonentTopRight.y > otherTopRight.y;
  }

  void followComponent(double speed, double dt, PositionComponent target) {
    final Vector2 direction = target.absoluteCenter - absoluteCenter;
    final double distance = direction.length;
    if (distance < _epsilon) return;
    direction.normalize();
    position += direction * min(speed * dt, distance);
    final maxX = GameConfig.worldSize.x - size.x;
    final maxY = GameConfig.worldSize.y - size.y;
    position.x = position.x.clamp(0.0, maxX);
    position.y = position.y.clamp(0.0, maxY);
  }
}
