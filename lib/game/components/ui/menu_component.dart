import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/game/components/ui/seed_panel_component.dart';
import 'package:game_jam/game/my_game.dart';

class MenuComponent extends PositionComponent
    with HasGameReference<MyGame>, TapCallbacks {
  final VoidCallback onStart;
  final Future<void> Function() onReroll;

  MenuComponent({required this.onStart, required this.onReroll})
    : super(priority: 100);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final menuWidth = game.camera.viewport.size.x * 0.3;
    final menuHeight = game.camera.viewport.size.y * 0.3;
    final menuSize = Vector2(menuWidth, menuHeight);

    // Listen to character debug state changes to update the menu
    // 1. Add a semi-transparent background
    add(
      ColumnComponent(
        gap: 1.0,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        size: menuSize,
        anchor: Anchor.center,
        position: (game.camera.viewport.virtualSize / 2),
        children: [
          ColumnComponent(
            gap: 1.0,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              TextComponent(
                text: 'GRONOUŸ',
                textRenderer: TextPaint(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextComponent(
                text: "Tadpole's Big Frogger",
                textRenderer: TextPaint(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
            ],
          ),

          // Seed
          SeedPanelComponent(
            size: Vector2(menuSize.x * 0.8, menuSize.y * 0.4),
            onReroll: onReroll,
            onStart: onStart,
          ),
        ],
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
  }

  @override
  void onRemove() {
    game.characterDebugState.removeListener(_syncDebugText);
    super.onRemove();
  }

  void _syncDebugText() {
    //   final CharacterDebugState? debugState = game.characterDebugState.value;
    //   if (debugState == null) {
    //     _nameText.text = '-';
    //     _detailsText.text = 'Seed: -\nColor: -';
    //     _layoutText();
    //     return;
    //   }
    //   _nameText.text = debugState.profile.name.display;
    //   _detailsText.text =
    //       'Seed: ${debugState.seedCode}\nColor: ${debugState.profile.colorHex}';
    //   _layoutText();
    // }

    // void _layoutText() {
    //   _detailsText.position = Vector2(0, _nameText.size.y + 4);
    //   _fpsText.position = Vector2(0, _nameText.size.y + _detailsText.size.y + 8);
    // }
  }
}
