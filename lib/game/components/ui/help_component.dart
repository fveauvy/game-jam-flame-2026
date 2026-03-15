import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/components/text/simple_text_component.dart';
import 'package:game_jam/game/my_game.dart';

class HelpComponent extends SpriteComponent
    with HoverCallbacks, TapCallbacks, HasGameReference<MyGame> {
  HelpComponent({super.size});

  @override
  FutureOr<void> onLoad() async {
    sprite = Sprite(game.images.fromCache(AssetPaths.plankCacheKey));
    add(
      SimpleTextComponent(
        text: 'Select a frog for start',
        color: const Color.fromARGB(255, 247, 222, 193),
        position: size / 2,
        anchor: Anchor.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
    return super.onLoad();
  }
}
