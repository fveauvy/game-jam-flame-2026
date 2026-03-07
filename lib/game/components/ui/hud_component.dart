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
    this.fpsTextStyle = const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12),
  }) : super(position: position ?? Vector2(16, 16), priority: 100);

  final TextStyle nameTextStyle;
  final TextStyle detailsTextStyle;
  final TextStyle fpsTextStyle;

  late final TextComponent _nameText = TextComponent(
    text: '-',
    textRenderer: TextPaint(style: nameTextStyle),
  );
  late final TextComponent _detailsText = TextComponent(
    text: 'Seed: -\nColor: -',
    textRenderer: TextPaint(style: detailsTextStyle),
  );
  late final TextComponent _fpsText = TextComponent(
    text: 'FPS: -',
    textRenderer: TextPaint(style: fpsTextStyle),
  );

  double _fpsElapsed = 0;
  int _fpsFrames = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await addAll([_nameText, _detailsText, _fpsText]);
    game.characterDebugState.addListener(_syncDebugText);
    _syncDebugText();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dt <= 0) {
      return;
    }
    _fpsElapsed += dt;
    _fpsFrames += 1;
    if (_fpsElapsed < 0.25) {
      return;
    }
    final double fps = _fpsFrames / _fpsElapsed;
    _fpsText.text = 'FPS: ${fps.toStringAsFixed(0)}';
    _fpsElapsed = 0;
    _fpsFrames = 0;
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
      _layoutText();
      return;
    }
    _nameText.text = debugState.profile.name.display;
    _detailsText.text =
        'Seed: ${debugState.seedCode}\nColor: ${debugState.profile.colorHex}';
    _layoutText();
  }

  void _layoutText() {
    _detailsText.position = Vector2(0, _nameText.size.y + 4);
    _fpsText.position = Vector2(0, _nameText.size.y + _detailsText.size.y + 8);
  }
}
