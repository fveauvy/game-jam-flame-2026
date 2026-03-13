import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
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
    this.fpsTextStyle = const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
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
  late final TextComponent _eggsText = TextComponent(
    text: 'Eggs: -',
    textRenderer: TextPaint(style: healthTextStyle),
  );

  static const double _barWidth = 120;
  static const double _barHeight = 10;

  late final RectangleComponent _moistureBarBg = RectangleComponent(
    size: Vector2(_barWidth, _barHeight),
    paint: Paint()..color = const Color(0x55FFFFFF),
  );
  late final RectangleComponent _moistureBarFill = RectangleComponent(
    size: Vector2(_barWidth, _barHeight),
    paint: Paint()..color = const Color(0xFF42A5F5),
  );
  late final TextComponent _moistureLabel = TextComponent(
    text: 'Moisture',
    textRenderer: TextPaint(
      style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12),
    ),
  );

  late final TextComponent _fpsText = TextComponent(
    text: 'FPS: -',
    anchor: Anchor.topRight,
    textRenderer: TextPaint(style: fpsTextStyle),
  );
  late final TextComponent _chronometerText = TextComponent(
    text: 'Time: -',
    anchor: Anchor.topRight,
    textRenderer: TextPaint(style: healthTextStyle),
  );

  double _fpsElapsed = 0;
  int _fpsFrames = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await addAll([
      _nameText,
      _healthText,
      _eggsText,
      _moistureBarBg,
      _moistureBarFill,
      _moistureLabel,
      _fpsText,
      _chronometerText,
    ]);
    game.characterState.addListener(_syncCharacterText);
    _syncCharacterText();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dt <= 0) {
      return;
    }
    _fpsElapsed += dt;
    _fpsFrames += 1;
    if (_fpsElapsed < GameplayTuning.hudFpsSampleWindowSeconds) {
      _syncHealthText();
      _syncEggsText();
      _syncChronometerText();
      _syncMoistureBar();
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
    _syncMoistureBar();
    _layoutText();
  }

  @override
  void onRemove() {
    game.characterState.removeListener(_syncCharacterText);
    super.onRemove();
  }

  void _syncCharacterText() {
    final CharacterProfile? profile = game.characterState.value;
    if (profile == null) {
      _nameText.text = '-';
      _healthText.text = 'Health: -';
      _layoutText();
      return;
    }
    _nameText.text = profile.name.display;
    _syncHealthText();
    _syncMoistureBar();
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

  void _syncMoistureBar() {
    final int? moisture = game.playerMoistureLevel;
    final double fraction = moisture == null
        ? 0
        : (moisture / GameplayTuning.initialMoistureLevel).clamp(0.0, 1.0);
    _moistureBarFill.size = Vector2(_barWidth * fraction, _barHeight);
    final Color fill = Color.lerp(
      const Color(0xFFF44336),
      const Color(0xFF42A5F5),
      fraction,
    )!;
    _moistureBarFill.paint = Paint()..color = fill;
  }

  void _syncEggsText() {
    final int savedEggs = game.gameState.savedEggs;
    _eggsText.text = 'Eggs: $savedEggs';
  }

  void _syncChronometerText() {
    final int elapsedTimeInMs = game.gameState.elapsedTimeInMs;
    final String formattedTime =
        "${(elapsedTimeInMs / 1000 / 60).round()}:${(elapsedTimeInMs / 1000 % 60).round().toString().padLeft(2, '0')}";
    _chronometerText.text = 'Time: $formattedTime';
  }

  void _layoutText() {
    _healthText.position = Vector2(0, _nameText.size.y + 4);
    _eggsText.position = Vector2(
      0,
      _healthText.position.y + _healthText.size.y + 4,
    );
    _moistureLabel.position = Vector2(
      0,
      _eggsText.position.y + _eggsText.size.y + 6,
    );
    _moistureBarBg.position = Vector2(
      0,
      _moistureLabel.position.y + _moistureLabel.size.y + 2,
    );
    _moistureBarFill.position = _moistureBarBg.position.clone();
    _chronometerText.position = Vector2(game.size.x - 16, 4);
    _fpsText.position = Vector2(
      game.size.x - 16,
      _chronometerText.position.y + _chronometerText.size.y + 4,
    );
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
