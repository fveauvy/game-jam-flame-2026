import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/components/ui/hud_component.dart';

void main() {
  test('fpsColor matches expected value bands', () {
    expect(HudComponent.fpsColor(30), const Color(0xFFF44336));
    expect(HudComponent.fpsColor(31), const Color(0xFFFF9800));
    expect(HudComponent.fpsColor(60), const Color(0xFFFF9800));
    expect(HudComponent.fpsColor(61), const Color(0xFFFFEB3B));
    expect(HudComponent.fpsColor(90), const Color(0xFFFFEB3B));
    expect(HudComponent.fpsColor(91), const Color(0xFF4CAF50));
  });
}
