import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/game/my_game.dart';

class SeedPanelComponent extends SpriteButtonComponent
    with HasGameReference<MyGame> {
  SeedPanelComponent({
    Anchor anchor = Anchor.topLeft,
    required this.onReroll,
    required this.onStart,
    required Vector2 size,
  }) : super(anchor: anchor, size: size);

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
      text: game.characterDebugState.value?.seedCode ?? "-",
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, letterSpacing: 2.0),
      ),
      anchor: Anchor.center,
      position: size / 2 - Vector2(5, 2),
    );

    game.characterDebugState.addListener(_updateSeedText);

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

  void _updateSeedText() {
    _seedText.text = game.characterDebugState.value?.seedCode ?? "-";
  }

  @override
  void onRemove() {
    game.characterDebugState.removeListener(_updateSeedText);
    super.onRemove();
  }
}
