import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:game_jam/game/character/model/character_debug_state.dart';
import 'package:game_jam/game/my_game.dart';

class HudComponent extends PositionComponent with HasGameReference<MyGame> {
  HudComponent({
    Vector2? position,
    this.nameTextStyle = const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 22,
      fontWeight: FontWeight.w700,
    ),
    this.detailsTextStyle = const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 14,
    ),
  }) : super(position: position ?? Vector2(16, 16), priority: 100);

  final TextStyle nameTextStyle;
  final TextStyle detailsTextStyle;

  late final TextComponent _nameText = TextComponent(
    text: '-',
    textRenderer: TextPaint(style: nameTextStyle),
  );
  late final TextComponent _detailsText = TextComponent(
    text: 'Seed: -\nColor: -',
    textRenderer: TextPaint(style: detailsTextStyle),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(_nameText);
    await add(_detailsText);
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
      _nameText.text = '-';
      _detailsText.text = 'Seed: -\nColor: -';
      _detailsText.position = Vector2(0, _nameText.size.y + 4);
      return;
    }
    _nameText.text = debugState.profile.name.display;
    _detailsText.text =
        'Seed: ${debugState.seedCode}\nColor: ${debugState.profile.colorHex}';
    _detailsText.position = Vector2(0, _nameText.size.y + 4);
  }
}
