import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/ui_config.dart';
import 'package:game_jam/game/character/model/character_generation_state.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/components/ui/help_component.dart';
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
          HelpComponent(size: Vector2(plankWidth, plankHeight)),
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
    : super(size: Vector2(194, 88), anchor: Anchor.center, priority: 220);

  late final TextComponent _nameText;
  late final TextComponent _intText;
  late final TextComponent _hpText;
  late final TextComponent _sizeText;
  late final TextComponent _speedText;
  bool _showPopover = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _nameText = TextComponent(
      text: '-',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 6),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final intIconImage = await Flame.images.load(
      AssetPaths.imageCacheKeyFromAssetPath(AssetPaths.uiIntelligenceLogo),
    );
    final hpIconImage = await Flame.images.load(
      AssetPaths.imageCacheKeyFromAssetPath(AssetPaths.uiHeartLogo),
    );
    final speedIconImage = await Flame.images.load(
      AssetPaths.imageCacheKeyFromAssetPath(AssetPaths.uiSpeedLogo),
    );

    _intText = TextComponent(
      text: '-',
      anchor: Anchor.centerLeft,
      position: Vector2(34, 45),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    _hpText = TextComponent(
      text: '-',
      anchor: Anchor.centerLeft,
      position: Vector2(34, 67),
      textRenderer: _intText.textRenderer,
    );
    _sizeText = TextComponent(
      text: '-',
      anchor: Anchor.centerLeft,
      position: Vector2(130, 67),
      textRenderer: _intText.textRenderer,
    );
    _speedText = TextComponent(
      text: '-',
      anchor: Anchor.centerLeft,
      position: Vector2(130, 45),
      textRenderer: _intText.textRenderer,
    );

    await addAll([
      _nameText,
      SpriteComponent(
        sprite: Sprite(intIconImage),
        anchor: Anchor.center,
        position: Vector2(19, 45),
        size: Vector2.all(15),
      ),
      SpriteComponent(
        sprite: Sprite(hpIconImage),
        anchor: Anchor.center,
        position: Vector2(19, 67),
        size: Vector2.all(15),
      ),
      SpriteComponent(
        sprite: Sprite(speedIconImage),
        anchor: Anchor.center,
        position: Vector2(115, 45),
        size: Vector2.all(15),
      ),
      TextComponent(
        text: '?',
        anchor: Anchor.center,
        position: Vector2(115, 67),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      _intText,
      _hpText,
      _sizeText,
      _speedText,
    ]);
  }

  @override
  void onMount() {
    super.onMount();
    game.characterGenerationState.addListener(_syncFromState);
    game.characterState.addListener(_syncFromState);
    _syncFromState();
  }

  @override
  void onRemove() {
    game.characterGenerationState.removeListener(_syncFromState);
    game.characterState.removeListener(_syncFromState);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.phase.value != GamePhase.menu &&
        game.phase.value != GamePhase.playing) {
      _showPopover = false;
      return;
    }

    final PlayerComponent? selected = _resolveTargetFrog();
    if (selected == null) {
      _showPopover = false;
      return;
    }
    _showPopover = true;

    final Vector2 viewport = game.camera.viewport.size;
    final Vector2 viewOrigin = game.camera.viewfinder.position;
    const double margin = 8;
    final double halfWidth = size.x * 0.5;
    final double halfHeight = size.y * 0.5;
    final double minX = viewOrigin.x + margin + halfWidth;
    final double maxX = viewOrigin.x + viewport.x - margin - halfWidth;
    final double minY = viewOrigin.y + margin + halfHeight;
    final double maxY = viewOrigin.y + viewport.y - margin - halfHeight;
    final double desiredDistance =
        (selected.size.y * 0.5) + (size.y * 0.5) + 10;

    final bool canPlaceAbove = selected.position.y - desiredDistance >= minY;
    final bool canPlaceBelow = selected.position.y + desiredDistance <= maxY;
    final bool placeBelow = !canPlaceAbove && canPlaceBelow;
    final double desiredY =
        selected.position.y + (placeBelow ? desiredDistance : -desiredDistance);

    position = Vector2(
      selected.position.x.clamp(minX, maxX),
      desiredY.clamp(minY, maxY),
    );
  }

  @override
  void render(Canvas canvas) {
    if (!_showPopover) {
      return;
    }

    final RRect panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(9),
    );
    canvas.drawRRect(panel, Paint()..color = const Color(0xE0221712));
    canvas.drawRRect(
      panel,
      Paint()
        ..color = Colors.white30
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 32, size.x, 1),
        const Radius.circular(1),
      ),
      Paint()..color = Colors.white24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(108, 37, 16, 16),
        const Radius.circular(4),
      ),
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    super.render(canvas);
  }

  void _syncFromState() {
    final CharacterProfile? profile = game.phase.value == GamePhase.menu
        ? game.characterGenerationState.value?.profile
        : game.characterState.value;
    if (profile == null) {
      _nameText.text = '-';
      _intText.text = '-';
      _hpText.text = '-';
      _sizeText.text = '-';
      _speedText.text = '-';
      return;
    }

    _nameText.text = profile.name.display;
    _intText.text = _fmt(profile.traits.intelligence);
    _hpText.text = profile.traits.health?.toString() ?? '-';
    _sizeText.text = _fmt(profile.traits.size);
    _speedText.text = _fmt(profile.traits.speed);
  }

  PlayerComponent? _resolveTargetFrog() {
    final List<PlayerComponent> candidates = game.playerCandidates;
    if (candidates.isEmpty) {
      return null;
    }

    if (game.phase.value == GamePhase.playing) {
      return candidates.first;
    }

    final CharacterGenerationState? state = game.characterGenerationState.value;
    if (state == null) {
      return null;
    }
    final int index = state.selectedIndex;
    if (index < 0 || index >= candidates.length) {
      return null;
    }
    return candidates[index];
  }

  String _fmt(double? value) {
    if (value == null) {
      return '-';
    }
    return value.toStringAsFixed(2);
  }
}
