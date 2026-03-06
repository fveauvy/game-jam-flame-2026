import 'package:flame/components.dart';

extension PositionComponentExtension on PositionComponent {
    bool hasPixelOutOfComponent(PositionComponent otherComponent) {
      final otherTopLeft = otherComponent.absolutePosition;
      final otherBottomLeft = otherComponent.absolutePosition + Vector2(0, otherComponent.size.y);
      final comonentTopLeft = absolutePosition;
      final comonentBottomLeft = absolutePosition + Vector2(0, size.y);
      final otherBottomRight = otherComponent.absolutePosition + otherComponent.size;
      final comonentBottomRight = absolutePosition + size;
      final otherTopRight = otherComponent.absolutePosition + Vector2(otherComponent.size.x, 0);
      final comonentTopRight = absolutePosition + Vector2(size.x, 0);
      
      return comonentBottomLeft.x < otherBottomLeft.x || 
          comonentBottomRight.x > otherBottomRight.x ||
          comonentTopLeft.y > otherTopLeft.y || 
          comonentTopRight.y > otherTopRight.y; 
  }
}