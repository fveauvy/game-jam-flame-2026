import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:game_jam/game/character/model/character_debug_state.dart';
import 'package:game_jam/game/my_game.dart';

class HudComponent extends TextComponent with HasGameReference<MyGame> {
  HudComponent()
    : super(
        text: 'Seed: -\nName: -\nColor: -',
        position: Vector2(16, 16),
        priority: 100,
        textRenderer: TextPaint(
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14),
        ),
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    game.characterDebugState.addListener(_syncDebugText);
    _syncDebugText();
  }

  @override
  void onRemove() {
    game.characterDebugState.removeListener(_syncDebugText);
    super.onRemove();
  }

  void _syncDebugText() {
    final CharacterDebugState? debugState = game.characterDebugState.value;
    if (debugState == null) {
      text = 'Seed: -\nName: -\nColor: -';
      return;
    }
    text =
        'Seed: ${debugState.seedCode}\nName: ${debugState.profile.name.display}\nColor: ${debugState.profile.colorHex}';
  }
}
