import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/game/my_game.dart';

class SeedPanelComponent extends SpriteButtonComponent
    with HasGameReference<MyGame>, HoverCallbacks {
  SeedPanelComponent({
    Anchor anchor = Anchor.center,
    required Vector2 position,
    required this.onReroll,
    required this.onStart,
    required Vector2 size,
  }) : super(anchor: anchor, size: size, position: position);

  late final TextComponent _seedText;
  final Future<void> Function() onReroll;
  final VoidCallback onStart;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    button = Sprite(game.images.fromCache('plank.png'));
    onPressed = () async {
      await onReroll();
    };

    _seedText = TextComponent(
      text: game.characterGenerationState.value?.seedCode ?? "-",
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, letterSpacing: 2.0),
      ),
      anchor: Anchor.center,
      position: size / 2 - Vector2(5, 2),
    );

    game.characterGenerationState.addListener(_updateSeedText);

    add(
      RowComponent(
        gap: 4.0,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        size: size,
        anchor: Anchor.center,
        position: size / 2,
        children: [
          _seedText,
          SpriteButtonComponent(
            button: Sprite(game.images.fromCache('refresh_logo.png')),
            size: Vector2(16, 16),
            // buttonDown: (game.images.fromCache('refresh_logo_down.png')),
            anchor: Anchor.center,
            position: size / 2 + Vector2(50, 0),
            onPressed: () async {
              await onReroll();
            },
          ),
        ],
      ),
    );
  }

  @override
  void onHoverEnter() {
    super.onHoverEnter();
    scale = Vector2.all(1.05);
  }

  @override
  void onHoverExit() {
    super.onHoverExit();
    scale = Vector2.all(1.0);
  }

  void _updateSeedText() {
    _seedText.text = game.characterGenerationState.value?.seedCode ?? "-";
  }

  @override
  void onRemove() {
    game.characterGenerationState.removeListener(_updateSeedText);
    super.onRemove();
  }
}
