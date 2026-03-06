import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class HudComponent extends TextComponent {
  HudComponent()
    : super(
        text: 'Template',
        position: Vector2(16, 16),
        priority: 100,
        textRenderer: TextPaint(
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
        ),
      );
}
