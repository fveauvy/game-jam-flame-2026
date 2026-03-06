import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class GroundComponent extends RectangleComponent {
  GroundComponent({required Vector2 position, required Vector2 size})
    : super(
        position: position,
        size: size,
        priority: 0,
        paint: Paint()..color = const Color(0xFF264653),
      );
}
