import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class SimpleTextComponent extends TextComponent {
  SimpleTextComponent({
    required Color color,
    required Vector2 position,
    required String text,
    TextStyle? style,
    int priority = 0,
    Anchor anchor = Anchor.topLeft,
  }) : super(
         text: text,
         position: position,
         priority: priority,
         anchor: anchor,
         textRenderer: TextPaint(
           style: (style ?? const TextStyle()).copyWith(
             color: color,
             fontSize: style?.fontSize ?? 14,
           ),
         ),
       );
}
