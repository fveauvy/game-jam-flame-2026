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
    this.healthTextStyle = const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 14,
    ),
    this.fpsTextStyle = const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12),
  }) : super(position: position ?? Vector2(16, 16), priority: 100);

  final TextStyle nameTextStyle;
  final TextStyle healthTextStyle;
  final TextStyle fpsTextStyle;

  late final TextComponent _nameText = TextComponent(
    text: '-',
    textRenderer: TextPaint(style: nameTextStyle),
  );
  late final TextComponent _healthText = TextComponent(
    text: 'Health: -',
    textRenderer: TextPaint(style: healthTextStyle),
  );
  late final TextComponent _fpsText = TextComponent(
    text: 'FPS: -',
    anchor: Anchor.topRight,
    textRenderer: TextPaint(style: fpsTextStyle),
  );

  double _fpsElapsed = 0;
  int _fpsFrames = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await addAll([_nameText, _healthText, _fpsText]);
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
      _syncHealthText();
      _layoutText();
      return;
    }
    final double fps = _fpsFrames / _fpsElapsed;
    _fpsText.text = 'FPS: ${fps.toStringAsFixed(0)}';
    _fpsText.textRenderer = TextPaint(
      style: fpsTextStyle.copyWith(color: fpsColor(fps)),
    );
    _fpsElapsed = 0;
    _fpsFrames = 0;
    _syncHealthText();
    _layoutText();
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
      _healthText.text = 'Health: -';
      _layoutText();
      return;
    }
    _nameText.text = debugState.profile.name.display;
    _syncHealthText();
    _layoutText();
  }

  void _syncHealthText() {
    final int? remainingHealth = game.playerRemainingHealth;
    final int? maxHealth = game.playerMaxHealth;
    if (remainingHealth == null || maxHealth == null) {
      _healthText.text = 'Health: -';
      return;
    }
    _healthText.text = 'Health: $remainingHealth/$maxHealth';
  }

  void _layoutText() {
    _healthText.position = Vector2(0, _nameText.size.y + 4);
    _fpsText.position = Vector2(game.size.x - 16, 16);
  }

  static Color fpsColor(double fps) {
    if (fps <= 30) {
      return const Color(0xFFF44336);
    }
    if (fps <= 60) {
      return const Color(0xFFFF9800);
    }
    if (fps <= 90) {
      return const Color(0xFFFFEB3B);
    }
    return const Color(0xFF4CAF50);
  }
}
