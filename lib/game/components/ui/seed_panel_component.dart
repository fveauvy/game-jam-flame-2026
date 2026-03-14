import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/my_game.dart';

class SeedPanelComponent extends SpriteButtonComponent
    with HasGameReference<MyGame>, HoverCallbacks, TapCallbacks {
  SeedPanelComponent({
    required Vector2 position,
    required this.onReroll,
    required Vector2 size,
  }) : super(size: size, position: position, anchor: Anchor.center);

  late final TextComponent _seedText;
  String _displayedSeedCode = '-';
  final Future<void> Function() onReroll;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    button = Sprite(game.images.fromCache(AssetPaths.plankCacheKey));

    _displayedSeedCode = game.characterSeedCode;

    _seedText = TextComponent(
      text: _displayedSeedCode,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, letterSpacing: 2.0),
      ),
      position: size / 2 - Vector2(5, 2),
    );

    add(
      RowComponent(
        gap: 4.0,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        size: size,
        children: [
          _seedText,
          SpriteComponent(
            sprite: Sprite(game.images.fromCache('ui/refresh_logo.png')),
            size: Vector2(16, 16),
            position: size / 2 + Vector2(50, 0),
          ),
        ],
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) async {
    super.onTapDown(event);
    scale = Vector2.all(.90);
    button = Sprite(game.images.fromCache('plank_dark.png'));
    await onReroll();
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    button = Sprite(game.images.fromCache('plank_light.png'));
    scale = Vector2.all(1.05);
  }

  @override
  void onHoverEnter() {
    super.onHoverEnter();
    scale = Vector2.all(1.05);
    button = Sprite(game.images.fromCache('plank_light.png'));
  }

  @override
  void onHoverExit() {
    super.onHoverExit();
    scale = Vector2.all(1.0);
    button = Sprite(game.images.fromCache('plank.png'));
  }

  @override
  void update(double dt) {
    super.update(dt);
    final String nextSeedCode = game.characterSeedCode;
    if (_displayedSeedCode == nextSeedCode) {
      return;
    }
    _displayedSeedCode = nextSeedCode;
    _seedText.text = nextSeedCode;
  }

  @override
  void onRemove() {
    super.onRemove();
  }
}
