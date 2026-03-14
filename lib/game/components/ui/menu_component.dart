import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/flame.dart';
import 'package:flame/image_composition.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/ui_config.dart';
import 'package:game_jam/game/character/model/character_generation_state.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/components/ui/seed_panel_component.dart';
import 'package:game_jam/game/my_game.dart';

class MenuComponent extends PositionComponent
    with HasGameReference<MyGame>, TapCallbacks {
  final Future<void> Function() onReroll;
  final _SelectedFrogStatsPopover _statsPopover = _SelectedFrogStatsPopover();

  MenuComponent({required this.onReroll})
    : super(priority: 100, position: GameConfig.playerSpawn);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final menuWidth = game.camera.viewport.size.x * MenuUi.menuWidthFactor;
    final menuHeight = game.camera.viewport.size.y * MenuUi.menuHeightFactor;
    final menuSize = Vector2(menuWidth, menuHeight);
    anchor = Anchor.center;

    // Cap plank size to a maximum of 359x98 while still
    // being proportional to the menu size.
    final plankWidth = math.min(menuSize.x * 0.8, 160.0);
    final plankHeight = math.min(menuSize.y * 0.4, 55.0);
    final titleImage = await Flame.images.load(AssetPaths.titleCacheKey);
    final titleRatio = titleImage.width / titleImage.height;

    debugPrint('${titleImage.height} ${titleImage.width}');
    debugPrint('$titleRatio');

    final titleHeight = menuSize.y * 0.25;
    final titleWidth = titleHeight * titleRatio;

    // Listen to character debug state changes to update the menu
    // 1. Add a semi-transparent background
    add(
      ColumnComponent(
        gap: 0,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        size: menuSize,
        anchor: Anchor.center,
        children: [
          CircleComponent(
            radius: menuSize.y * 0.35,
            scale: Vector2(1, 0.40),
            position: Vector2(menuSize.x / 2, menuSize.y * 0.4),
            anchor: Anchor.center,
            paint: Paint()
              ..blendMode = BlendMode.multiply
              ..color = Colors.black.withValues(
                alpha: 0.8,
                blue: 0.9,
                green: 0.65,
                red: 0.4,
              )
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
          ),
          SpriteComponent(
            size: Vector2(titleWidth, titleHeight),
            sprite: Sprite(titleImage),
            anchor: Anchor.center,
            priority: 100,
            position: Vector2(menuSize.x / 2, menuSize.y * 0.35),
          ),
          SeedPanelComponent(
            size: Vector2(plankWidth, plankHeight),
            onReroll: onReroll,
            position: Vector2(menuSize.x / 2, menuSize.y * 0.58),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> onMount() async {
    super.onMount();
    if (_statsPopover.parent == null) {
      await game.world.add(_statsPopover);
    }
  }

  @override
  void onRemove() {
    _statsPopover.removeFromParent();
    super.onRemove();
  }
}

class _SelectedFrogStatsPopover extends PositionComponent
    with HasGameReference<MyGame> {
  _SelectedFrogStatsPopover()
    : super(size: Vector2(210, 92), anchor: Anchor.center, priority: 220);

  late final TextComponent _nameText;
  late final TextComponent _statsText;
  bool _showPopover = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _nameText = TextComponent(
      text: '-',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 8),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    _statsText = TextComponent(
      text: '-',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 28),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          height: 1.25,
        ),
      ),
    );

    await addAll([_nameText, _statsText]);
  }

  @override
  void onMount() {
    super.onMount();
    game.characterGenerationState.addListener(_syncFromState);
    _syncFromState();
  }

  @override
  void onRemove() {
    game.characterGenerationState.removeListener(_syncFromState);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final CharacterGenerationState? state = game.characterGenerationState.value;
    if (game.phase.value != GamePhase.menu || state == null) {
      _showPopover = false;
      return;
    }

    final int index = state.selectedIndex;
    final List<PlayerComponent> candidates = game.playerCandidates;
    if (index < 0 || index >= candidates.length) {
      _showPopover = false;
      return;
    }

    final PlayerComponent selected = candidates[index];
    _showPopover = true;

    final double verticalOffset = (selected.size.y * 0.95) + 52;
    final double halfPanelHeight = game.camera.viewport.size.y * 0.5;
    final double aboveY = selected.position.y - verticalOffset;
    final double belowY = selected.position.y + verticalOffset;
    bool placeBelow = aboveY - halfPanelHeight < 8;

    // If below would go off-screen, force it back above.
    if (belowY + halfPanelHeight > GameConfig.worldSize.y - 8) {
      placeBelow = false;
    }

    position =
        selected.position +
        Vector2(
          0,
          placeBelow
              ? ((selected.size.y * 0.95) + 52)
              : (-(selected.size.y * 0.95) - 52),
        );
  }

  @override
  void render(Canvas canvas) {
    if (!_showPopover) {
      return;
    }

    final RRect panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      panel,
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );
    canvas.drawRRect(
      panel,
      Paint()
        ..color = Colors.white30
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    super.render(canvas);
  }

  void _syncFromState() {
    final CharacterGenerationState? state = game.characterGenerationState.value;
    if (state == null) {
      _nameText.text = '-';
      _statsText.text = '-';
      return;
    }

    final CharacterProfile profile = state.profile;
    _nameText.text = profile.name.display;
    _statsText.text =
        'SPD ${_fmt(profile.traits.speed)}   SIZE ${_fmt(profile.traits.size)}\n'
        'INT ${_fmt(profile.traits.intelligence)}   HP ${profile.traits.health ?? '-'}';
  }

  String _fmt(double? value) {
    if (value == null) {
      return '-';
    }
    return value.toStringAsFixed(2);
  }
}
